//
//  CodableMacro+Generate.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/1/30.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



extension CodableMacro {
    
    struct EnumDeclSpec {
        let name: TokenSyntax
        let cases: [String]
    }


    private static func generateSingleEnumDeclaration<Cases: Collection>(
        name: TokenSyntax, 
        cases: Cases
    ) -> DeclSyntax 
    where Cases.Element == String {
        """
        enum \(name): String, CodingKey {
            case \(raw: cases.map { #"k\#($0) = "\#($0)""# }.joined(separator: ","))
        }
        """
    }


    static func generateEnumDeclarations(from structure: CodingStructure, macroNode: AttributeSyntax) throws -> [DeclSyntax] {

        let enumNamePrefix = "$__coding_container_keys_" as TokenSyntax

        var containerStack: [TokenSyntax] = []
        var enumDecls = [DeclSyntax]() 


        func dfs(_ structure: CodingStructure) throws {

            switch structure {

                case let .root(children, _):
                    let containerName = "root" as TokenSyntax
                    enumDecls.append(
                        generateSingleEnumDeclaration(name: "\(enumNamePrefix)\(containerName)", cases: children.keys)
                    )
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    for child in children.values {
                        try dfs(child)
                    }

                case let .node(pathElement, children, _):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    enumDecls.append(
                        generateSingleEnumDeclaration(name: "\(enumNamePrefix)\(containerName)", cases: children.keys)
                    )
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    for child in children.values {
                        try dfs(child)
                    }

                case .leaf: break 

            }

        }

        try dfs(structure)

        return enumDecls

    }


    static func generateDecodeInitializer(
        from structure: CodingStructure,
        isClass: Bool,
        inherit: Bool,
        macroNode: AttributeSyntax
    ) throws -> DeclSyntax {

        let containerCodingKeysPrefix = "$__coding_container_keys_" as TokenSyntax
        let containerVarNamePrefix = "$__coding_container_" as TokenSyntax

        var containerStack: [TokenSyntax] = []

        func structureDfs(_ structure: CodingStructure) throws -> (items: [CodeBlockItemSyntax], fieldsWithDefault: [CodingFieldInfo]) {

            var codeBlockItems = [CodeBlockItemSyntax]()
            var fieldsWithDefault = [CodingFieldInfo]()

            var initFieldsWithDefaultCodeBlockItems: [CodeBlockItemSyntax] {
                get throws {
                    try fieldsWithDefault.map { 
                        if let defaultValue = $0.defaultValue {
                            "self.\($0.propertyInfo.name) = \(defaultValue)"
                        } else if $0.propertyInfo.initializer == nil, $0.propertyInfo.hasOptionalTypeDecl {
                            "self.\($0.propertyInfo.name) = nil"
                        } else {
                            throw .diagnostic(node: $0.propertyInfo.name, message: .codingMacro.codable.missingDefaultOrOptional)
                        }
                    }
                }
            }

            switch structure {

                case let .root(children, isRequired): do {

                    let containerName = "root" as TokenSyntax

                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }

                    let items = try children.values.flatMap { child in
                        let (childItems, childFieldsWithDefault) = try structureDfs(child)
                        fieldsWithDefault.append(contentsOf: childFieldsWithDefault)
                        return childItems
                    }

                    guard !items.isEmpty else { break }

                    codeBlockItems = try generateRootDecodeItems(
                        containerVarName: "\(containerVarNamePrefix)\(containerName)" as TokenSyntax, 
                        containerCodingKeysName: "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax, 
                        isRequired: isRequired, 
                        childDecodingItems: items, 
                        fieldsWithDefaultInitItems: initFieldsWithDefaultCodeBlockItems
                    )

                }

                case let .node(pathElement, children, isRequired): do {

                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax

                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }

                    let items = try children.values.flatMap { child in
                        let (childItems, childFieldsWithDefault) = try structureDfs(child)
                        fieldsWithDefault.append(contentsOf: childFieldsWithDefault)
                        return childItems
                    }

                    guard !items.isEmpty else { break }

                    codeBlockItems = try generateContainerDecodeItems(
                        parentContainerVarName: "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax, 
                        containerVarName: "\(containerVarNamePrefix)\(containerName)" as TokenSyntax, 
                        containerCodingKeysName: "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax, 
                        pathElement: pathElement, 
                        isRequired: isRequired, 
                        childDecodingItems: items, 
                        fieldsWithDefaultInitItems: initFieldsWithDefaultCodeBlockItems
                    )

                }

                case let .leaf(pathElement, field): do {

                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    let propertyInfo = field.propertyInfo

                    if field.defaultValue != nil || (propertyInfo.initializer == nil && propertyInfo.hasOptionalTypeDecl) {
                        fieldsWithDefault.append(field)
                    }

                    guard propertyInfo.type != .constant || propertyInfo.initializer == nil else {
                        // a let constant with an initializer cannot be decoded, ignore it
                        break
                    }

                    codeBlockItems.append(
                        try field.makeDecodeBlock(containerVarName: parentContainerVarName, pathElement: pathElement)
                    )

                }

            }

            return (codeBlockItems, fieldsWithDefault)

        }

        return .init(
            try InitializerDeclSyntax("public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws") {
                CodingFieldInfo.transformFunctionDecl
                CodingFieldInfo.validationFunctionDecl
                try structureDfs(structure).items
                if inherit {
                    "try super.init(from: decoder)"
                }
            }
        )

    }


    static func generateEncodeMethod(
        from structure: CodingStructure,
        inherit: Bool,
        macroNode: AttributeSyntax
    ) throws -> DeclSyntax {

        let containerCodingKeysPrefix = "$__coding_container_keys_" as TokenSyntax
        let containerVarNamePrefix = "$__coding_container_" as TokenSyntax

        var containerStack: [TokenSyntax] = []

        func structureDfs(_ structure: CodingStructure) throws -> [CodeBlockItemSyntax] {

            var items = [CodeBlockItemSyntax]()

            switch structure {

                case let .root(children, _):
                    let containerName = "root" as TokenSyntax
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    items = try generateRootEncodeItems(
                        containerVarName: "\(containerVarNamePrefix)\(containerName)" as TokenSyntax, 
                        containerCodingKeysName: "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax, 
                        childDecodingItems: children.values.flatMap { try structureDfs($0) }
                    )

                case let .node(pathElement, children, _):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    items = try generateContainerEncodeItems(
                        parentContainerVarName: "\(containerVarNamePrefix)\(parentContainerName)", 
                        containerVarName: "\(containerVarNamePrefix)\(containerName)", 
                        containerCodingKeysName: "\(containerCodingKeysPrefix)\(containerName)", 
                        pathElement: pathElement, 
                        childDecodingItems: children.values.flatMap { try structureDfs($0) }
                    )

                case let .leaf(pathElement, field):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    try items.append(field.makeEncodeBlock(containerVarName: parentContainerVarName, pathElement: pathElement))

            }

            return items

        }

        return try .init(
            FunctionDeclSyntax("public \(raw: inherit ? "override " : "")func encode(to encoder: Encoder) throws") {
                if inherit {
                    "try super.encode(to: encoder)"
                }
                CodingFieldInfo.transformFunctionDecl
                try structureDfs(structure)
            }
        )

    }
    
}



extension CodableMacro {

    private static func generateRootDecodeItems(
        containerVarName: TokenSyntax,
        containerCodingKeysName: TokenSyntax,
        isRequired: Bool,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsWithDefaultInitItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {

        var codeBlockItems = [CodeBlockItemSyntax]()

        if isRequired {
            codeBlockItems.append(
                "let \(containerVarName) = try decoder.container(keyedBy: \(containerCodingKeysName).self)"
            )
            codeBlockItems.append(contentsOf: childDecodingItems)
        } else {
            let decodeExpr = "try? decoder.container(keyedBy: \(containerCodingKeysName).self)" as ExprSyntax
            let decodeSubtreeExpr = try IfExprSyntax("if let \(containerVarName) = \(decodeExpr)") {
                childDecodingItems
            } else: {
                fieldsWithDefaultInitItems
            }
            codeBlockItems.append(.init(item: .expr(.init(decodeSubtreeExpr))))
        }

        return codeBlockItems

    }


    private static func generateContainerDecodeItems(
        parentContainerVarName: TokenSyntax,
        containerVarName: TokenSyntax,
        containerCodingKeysName: TokenSyntax,
        pathElement: String,
        isRequired: Bool,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsWithDefaultInitItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {

        var codeBlockItems = [CodeBlockItemSyntax]()

        if isRequired {
            codeBlockItems.append("""
                let \(containerVarName) = try \(parentContainerVarName).nestedContainer(
                    keyedBy: \(containerCodingKeysName).self, 
                    forKey: .k\(raw: pathElement)
                )
                """
            )
            codeBlockItems.append(contentsOf: childDecodingItems)
        } else {
            let decodeExpr = """
                try? \(parentContainerVarName).nestedContainer(
                    keyedBy: \(containerCodingKeysName).self, 
                    forKey: .k\(raw: pathElement)
                )
                """ as ExprSyntax
            let decodeSubtreeExpr = try IfExprSyntax("if let \(containerVarName) = \(decodeExpr)") {
                childDecodingItems
            } else: {
                fieldsWithDefaultInitItems
            }
            codeBlockItems.append(.init(item: .expr(.init(decodeSubtreeExpr))))
        }

        return codeBlockItems

    }


    private static func generateContainerEncodeItems(
        parentContainerVarName: TokenSyntax,
        containerVarName: TokenSyntax,
        containerCodingKeysName: TokenSyntax,
        pathElement: String,
        childDecodingItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {

        var codeBlockItems = [CodeBlockItemSyntax]()

        codeBlockItems.append("""
            var \(containerVarName) = \(parentContainerVarName).nestedContainer(
                keyedBy: \(containerCodingKeysName).self, 
                forKey: .k\(raw: pathElement)
            )
            """
        )
        codeBlockItems.append(contentsOf: childDecodingItems)

        return codeBlockItems

    }


    private static func generateRootEncodeItems(
        containerVarName: TokenSyntax,
        containerCodingKeysName: TokenSyntax,
        childDecodingItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {
        var codeBlockItems = [CodeBlockItemSyntax]()
        codeBlockItems.append("var \(containerVarName) = encoder.container(keyedBy: \(containerCodingKeysName).self)")
        codeBlockItems.append(contentsOf: childDecodingItems)
        return codeBlockItems
    }

}



extension CodableMacro.CodingFieldInfo {

    static var transformFunctionName: TokenSyntax { "$__coding_transform" }
    static var validateFunctionName: TokenSyntax { "$__coding_validate" }

    static var transformFunctionDecl: DeclSyntax {
        """
        func \(transformFunctionName)<T, R>(_ value: T, _ transform: (T) throws -> R) throws -> R {
            return try transform(value)
        }
        """
    }

    static var validationFunctionDecl: DeclSyntax {
        #"""
        func \#(validateFunctionName)<T>(_ propertyName: String, _ validateExpr: String, _ value: T, _ validate: (T) throws -> Bool) throws {
            guard (try? validate(value)) == true else {
                throw CodingValidationError(type: "\(Self.self)", property: propertyName, validationExpr: validateExpr, value: "\(value as Any)")
            }
        }
        """#
    }


    func makeDecodeBlock(containerVarName: TokenSyntax, pathElement: String) throws -> CodeBlockItemSyntax {
        let doStmt = try DoStmtSyntax("do") {
            try self.makeDecodeExpr(parentContainerVarName: containerVarName, pathElement: pathElement, resultVarName: "rawValue")
            try self.makeDecodeTransformExprs(sourceVarName: "rawValue", destVarName: "value")
            try self.makeValidateionExprs(varName: "value")
            try self.makeAssignmentExpr(varName: "value")
        }
        return .init(item: .stmt(.init(doStmt)))
    }


    func makeEncodeBlock(containerVarName: TokenSyntax, pathElement: String) throws -> CodeBlockItemSyntax {
        if self.propertyInfo.hasOptionalTypeDecl {
            let expr = try IfExprSyntax("if let value = self.\(propertyInfo.name)") {
                try self.makeEncodeTransformExprs(sourceVarName: "value", destVarName: "transformedValue")
                "try \(containerVarName).encode(transformedValue, forKey: .k\(raw: pathElement))"
            }
            return .init(item: .expr(.init(expr)))
        } else {
            let expr = try DoStmtSyntax("do") {
                try self.makeEncodeTransformExprs(sourceVarName: "self.\(propertyInfo.name)", destVarName: "transformedValue")
                "try \(containerVarName).encode(transformedValue, forKey: .k\(raw: pathElement))"
            }
            return .init(item: .stmt(.init(expr)))
        }
    }


    func makeDecodeExpr(parentContainerVarName: TokenSyntax, pathElement: String, resultVarName: TokenSyntax) throws -> CodeBlockItemSyntax {
        guard let typeExpression = propertyInfo.typeExpression else {
            throw .diagnostic(node: propertyInfo.name, message: .codingMacro.general.cannotInferType)
        }
        return if self.isRequired {
            """
            let \(resultVarName) = try \(parentContainerVarName).decode(
                \(self.decodeTransform?.decodeSourceType ?? typeExpression),
                forKey: .k\(raw: pathElement)
            )
            """
        } else {
            """
            let \(resultVarName) = try? \(parentContainerVarName).decode(
                \(self.decodeTransform?.decodeSourceType ?? typeExpression),
                forKey: .k\(raw: pathElement)
            )
            """
        } as CodeBlockItemSyntax
    }


    func makeEncodeTransformExprs(sourceVarName: TokenSyntax, destVarName: TokenSyntax) throws -> [CodeBlockItemSyntax] {
        guard let transformExprs = self.encodeTransform else { 
            return ["let \(destVarName) = \(sourceVarName)"] 
        }
        return transformExprs.enumerated().map { i, transform in
            let localSourceVarName = i == 0 ? sourceVarName : "value\(raw: i)" as TokenSyntax
            let localDestVarName = i == transformExprs.count - 1 ? destVarName : "value\(raw: i + 1)" as TokenSyntax
            return "let \(localDestVarName) = try \(Self.transformFunctionName)(\(localSourceVarName), \(transform))"
        }
    }


    func makeDecodeTransformExprs(sourceVarName: TokenSyntax, destVarName: TokenSyntax) throws -> [CodeBlockItemSyntax] {

        switch (self.decodeTransform, self.isRequired) {
            case let (.some(transformSpec), true):
                transformSpec.transformExprs.enumerated().map { i, transform in
                    let localSourceVarName = i == 0 ? sourceVarName : "value\(raw: i)" as TokenSyntax
                    let localDestVarName = i == transformSpec.transformExprs.count - 1 ? destVarName : "value\(raw: i + 1)" as TokenSyntax
                    return "let \(localDestVarName) = try \(Self.transformFunctionName)(\(localSourceVarName), \(transform))"
                }
            case let (.some(transformSpec), false):
                transformSpec.transformExprs.enumerated().map { i, transform in
                    let localSourceVarName = i == 0 ? sourceVarName : "value\(raw: i)" as TokenSyntax
                    let localDestVarName = i == transformSpec.transformExprs.count - 1 ? destVarName : "value\(raw: i + 1)" as TokenSyntax
                    return "let \(localDestVarName) = \(localSourceVarName).flatMap({ try? \(Self.transformFunctionName)($0, \(transform))})"
                }
            default:
                ["let \(destVarName) = \(sourceVarName)"]
        } as [CodeBlockItemSyntax]

    }

    
    func makeValidateionExprs(varName: TokenSyntax) throws -> [CodeBlockItemSyntax] {

        if self.validateExprs.isEmpty {
            [CodeBlockItemSyntax]()
        } else if self.isRequired {
            self.validateExprs.map { expr in
                let exprString = StringLiteralExprSyntax(content: IndentRemover().visit(expr).formatted().description)
                return #"try \#(Self.validateFunctionName)("\#(propertyInfo.name)", \#(exprString), \#(varName), \#(expr))"#
            } as [CodeBlockItemSyntax]
        } else {
            [
                CodeBlockItemSyntax(item: .expr(.init(
                    try IfExprSyntax("if let \(varName)") {
                        self.validateExprs.map { expr in
                            let exprString = StringLiteralExprSyntax(content: IndentRemover().visit(expr).formatted().description)
                            return #"try \#(Self.validateFunctionName)("\#(propertyInfo.name)", \#(exprString), \#(varName), \#(expr))"#
                        }
                    }
                )))
            ]
        }

    }

    
    func makeAssignmentExpr(varName: TokenSyntax) throws -> CodeBlockItemSyntax {
        
        if let defaultValue = self.defaultValue {
            "self.\(propertyInfo.name) = \(varName) ?? \(defaultValue)"
        } else if let initializer = propertyInfo.initializer {
            "self.\(propertyInfo.name) = \(varName) ?? \(initializer)"
        } else if propertyInfo.hasOptionalTypeDecl {
            "self.\(propertyInfo.name) = \(varName) ?? nil"
        } else {
            "self.\(propertyInfo.name) = \(varName)"
        }
        
    }

}