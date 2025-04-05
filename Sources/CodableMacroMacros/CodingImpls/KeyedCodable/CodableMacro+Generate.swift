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



/// MARK: CodingKey enums
extension CodableMacro {

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

                case let .sequenceLeaf(pathElement, _, subTree):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    try dfs(subTree)

                case .leaf: break 

            }

        }

        func dfs(_ structure: CodingSequenceSubStructure) throws {

            switch structure {
                case let .root(children, _): do {
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: "root")" as TokenSyntax
                    enumDecls.append(
                        generateSingleEnumDeclaration(name: "\(enumNamePrefix)\(containerName)", cases: children.keys)
                    )
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    for child in children.values {
                        try dfs(child)
                    }
                }
                case let .node(pathElement, children, _): do {
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
                }
                case .leaf: break
            }

        }

        try dfs(structure)

        return enumDecls

    }

}



/// MARK: Decode/Encode
extension CodableMacro {

    static func generateDecodeInitializer(
        from structure: CodingStructure,
        isClass: Bool,
        inherit: Bool,
        macroNode: AttributeSyntax
    ) throws -> DeclSyntax {

        var containerStack: [TokenSyntax] = []

        func structureDfs(_ structure: CodingStructure) throws -> (items: [CodeBlockItemSyntax], fieldsWithDefault: [CodingFieldInfo]) {

            var codeBlockItems = [CodeBlockItemSyntax]()
            var fieldsToInitOnError = [CodingFieldInfo]()

            switch structure {

                case let .root(children, requirementStrategy): do {

                    let containerName = "root" as TokenSyntax

                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }

                    let items = try children.values.flatMap { child in
                        let (childItems, childFieldsWithDefault) = try structureDfs(child)
                        fieldsToInitOnError.append(contentsOf: childFieldsWithDefault)
                        return childItems
                    }
                    guard !items.isEmpty else { break }

                    codeBlockItems = try generateRootDecodeItems(
                        containerName: containerName,
                        requirementStrategy: requirementStrategy,
                        childDecodingItems: items, 
                        fieldsToInitOnError: fieldsToInitOnError
                    )

                }

                case let .node(pathElement, children, requirementStrategy): do {

                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax

                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }

                    let items = try children.values.flatMap { child in
                        let (childItems, childFieldsWithDefault) = try structureDfs(child)
                        fieldsToInitOnError.append(contentsOf: childFieldsWithDefault)
                        return childItems
                    }

                    guard !items.isEmpty else { break }

                    codeBlockItems = try generateContainerDecodeItems(
                        parentContainerName: parentContainerName,
                        containerName: containerName,
                        pathElement: pathElement, 
                        requirementStrategy: requirementStrategy, 
                        childDecodingItems: items, 
                        fieldsToInitOnError: fieldsToInitOnError
                    )

                }

                case let .leaf(pathElement, field): do {

                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    let propertyInfo = field.propertyInfo

                    if (
                        field.defaultValueOnMisMatch != nil || field.defaultValueOnMissing != nil 
                        || (propertyInfo.initializer == nil && propertyInfo.hasOptionalTypeDecl) 
                    ) {
                        fieldsToInitOnError.append(field)
                    }

                    guard propertyInfo.type != .constant || propertyInfo.initializer == nil else {
                        // a let constant with an initializer cannot be decoded, ignore it
                        break
                    }

                    codeBlockItems.append(
                        try field.makeDecodeBlock(containerVarName: parentContainerVarName, pathElement: pathElement)
                    )

                }

                case let .sequenceLeaf(pathElement, fields, subTree): do {
                    
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax

                    let decodeExpr = """
                        var \(containerVarName) = try \(parentContainerVarName).nestedUnkeyedContainer(
                            forKey: .k\(raw: pathElement)
                        )
                        """ as CodeBlockItemSyntax

                    fieldsToInitOnError.append(
                        contentsOf: fields.filter { 
                            $0.defaultValueOnMisMatch != nil || $0.defaultValueOnMissing != nil 
                            || ($0.propertyInfo.initializer == nil && $0.propertyInfo.hasOptionalTypeDecl)  
                        }
                    )

                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }

                    var expr = try DoStmtSyntax("do") {
                        decodeExpr
                        for field in fields {
                            if let sequenceElementCodingInfo = field.sequenceElementCodingFieldInfo {
                                let typeExpr = sequenceElementCodingInfo.elementEncodedType 
                                let makeEmptyArrExpr = "\(CodingFieldInfo.makeEmptyArrayFunctionName)(ofType: \(typeExpr))" as ExprSyntax
                                let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyInfo.name)" as TokenSyntax
                                "var \(sequenceDecodeTempVarName) = \(makeEmptyArrExpr)"
                            } else {
                                throw InternalError(message: "Expected sequence element coding info")
                            }
                        }
                        try WhileStmtSyntax("while !\(containerVarName).isAtEnd")  {
                            try generateSequenceDecodeItems(from: subTree, containerStack: &containerStack, macroNode: macroNode).items
                        }
                        for field in fields {
                            if let sequenceElementCodingInfo = field.sequenceElementCodingFieldInfo {
                                let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyInfo.name)" as TokenSyntax
                                try DoStmtSyntax("do") {
                                    if let transformExpr = sequenceElementCodingInfo.decodeTransformExpr {
                                        "let rawValue = try \(CodingFieldInfo.transformFunctionName)(\(sequenceDecodeTempVarName), \(transformExpr))"
                                    } else {
                                        "let rawValue = \(sequenceDecodeTempVarName)"
                                    }
                                    try field.makeDecodeTransformExprs(sourceVarName: "rawValue", destVarName: "value")
                                    try field.makeValidateionExprs(varName: "value")
                                    "self.\(field.propertyInfo.name) = value"
                                }
                            } else {
                                throw InternalError(message: "Expected sequence element coding info")
                            }
                        }
                    }

                    try addCatchClauses(
                        to: &expr, 
                        fieldsWithDefault: fieldsToInitOnError, 
                        requirementStrategy: fields.reduce(.allowAll) { $0 | $1.requirementStrategy }
                    )

                    codeBlockItems.append(.init(item: .stmt(.init(expr))))

                }

            }

            return (codeBlockItems, fieldsToInitOnError)

        }

        return .init(
            try InitializerDeclSyntax("public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws") {
                CodingFieldInfo.transformFunctionDecl
                CodingFieldInfo.validationFunctionDecl
                CodingFieldInfo.makeEmptyArrayFunctionDecl
                try structureDfs(structure).items
                if inherit {
                    "try super.init(from: decoder)"
                }
            }
        )

    }


    static func generateSequenceDecodeItems(
        from structure: CodingSequenceSubStructure,
        containerStack: inout [TokenSyntax],
        macroNode: AttributeSyntax
    ) throws -> (items: [CodeBlockItemSyntax], fieldsWithDefault: [SequenceElementCodingFieldInfo]) {

        var codeBlockItems = [CodeBlockItemSyntax]()
        var fieldsToInitOnError = [SequenceElementCodingFieldInfo]()

        switch structure {
            case let .root(children, requirementStrategy): do {

                guard let parentUnkeyedContainerName = containerStack.last else {
                    throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                }
                let parentUnkeyedContainerVarName = "\(containerVarNamePrefix)\(parentUnkeyedContainerName)" as TokenSyntax
                let containerName = "\(parentUnkeyedContainerName)_\(raw: "root")" as TokenSyntax
                let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
                let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax

                containerStack.append(containerName)
                defer { containerStack.removeLast() }

                let decodeExpr = """
                    let \(containerVarName) = try \(parentUnkeyedContainerVarName).nestedContainer(
                        keyedBy: \(containerCodingKeysName).self
                    )
                    """ as CodeBlockItemSyntax

                let items = try children.values.flatMap { 
                    let (items, childFieldsToInitOnError) = try generateSequenceDecodeItems(from: $0, containerStack: &containerStack, macroNode: macroNode)
                    fieldsToInitOnError.append(contentsOf: childFieldsToInitOnError)
                    return items
                }
                if requirementStrategy == .always {
                    codeBlockItems.append(decodeExpr)
                    codeBlockItems.append(contentsOf: items)
                } else {
                    var expr = try DoStmtSyntax("do") {
                        decodeExpr
                        items
                    }
                    let typeMismatchCatchClause = CatchClauseSyntax([
                        .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.typeMismatch" as ExprSyntax))
                    ]) {
                        fieldsToInitOnError.compactMap { field in 
                            let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyName)" as TokenSyntax
                            return switch field.defaultValueOnMismatch {
                                case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                                default: nil 
                            }
                        }
                        "try \(parentUnkeyedContainerVarName).skip()"
                    }
                    let missingCatchClause = CatchClauseSyntax([
                        .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.keyNotFound" as ExprSyntax))
                    ]) {
                        fieldsToInitOnError.compactMap { field in 
                            let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyName)" as TokenSyntax
                            return switch field.defaultValueOnMissing {
                                case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                                default: nil 
                            }
                        }
                        "try \(parentUnkeyedContainerVarName).skip()"
                    }
                    let catchClause = switch requirementStrategy {
                        case .allowAll: [missingCatchClause, typeMismatchCatchClause]
                        case .allowMismatch: [typeMismatchCatchClause]
                        case .allowMissing: [missingCatchClause]
                        case .always: throw InternalError(message: "Unexpected `.always` requirement strategy when generating catch clause")
                    } as [CatchClauseSyntax]
                    expr.catchClauses.append(contentsOf: catchClause)
                    codeBlockItems.append(.init(item: .stmt(.init(expr))))
                }
            }
            case let .node(pathElement, children, requirementStrategy): do {
                guard let parentContainerName = containerStack.last else {
                    throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                }
                let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
                let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax
                let decodeExpr = """
                    let \(containerVarName) = try \(parentContainerVarName).nestedContainer(
                        keyedBy: \(containerCodingKeysName).self, 
                        forKey: .k\(raw: pathElement)
                    )
                    """ as CodeBlockItemSyntax
                containerStack.append(containerName)
                defer { containerStack.removeLast() }
                let items = try children.values.flatMap { 
                    let (items, childFieldsToInitOnError) = try generateSequenceDecodeItems(from: $0, containerStack: &containerStack, macroNode: macroNode)
                    fieldsToInitOnError.append(contentsOf: childFieldsToInitOnError)
                    return items
                }
                if requirementStrategy == .always {
                    codeBlockItems.append(decodeExpr)
                    codeBlockItems.append(contentsOf: items)
                } else {
                    var expr = try DoStmtSyntax("do") {
                        decodeExpr
                        items
                    }
                    let typeMismatchCatchClause = CatchClauseSyntax([
                        .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.typeMismatch" as ExprSyntax))
                    ]) {
                        fieldsToInitOnError.compactMap { field in 
                            let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyName)" as TokenSyntax
                            return switch field.defaultValueOnMismatch {
                                case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                                default: nil 
                            }
                        }
                    }
                    let missingCatchClause = CatchClauseSyntax([
                        .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.keyNotFound" as ExprSyntax))
                    ]) {
                        fieldsToInitOnError.compactMap { field in 
                            let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyName)" as TokenSyntax
                            return switch field.defaultValueOnMissing {
                                case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                                default: nil 
                            }
                        }
                    }
                    let catchClause = switch requirementStrategy {
                        case .allowAll: [missingCatchClause, typeMismatchCatchClause]
                        case .allowMismatch: [typeMismatchCatchClause]
                        case .allowMissing: [missingCatchClause]
                        case .always: throw InternalError(message: "Unexpected `.always` requirement strategy when generating catch clause")
                    } as [CatchClauseSyntax]
                    expr.catchClauses.append(contentsOf: catchClause)
                    codeBlockItems.append(.init(item: .stmt(.init(expr))))
                }
            }
            case let .leaf(pathElement, field): do {
                guard let parentContainerName = containerStack.last else {
                    throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                }
                let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyName)" as TokenSyntax
                if field.requirementStrategy != .always {
                    fieldsToInitOnError.append(field)
                }
                var expr = try DoStmtSyntax("do") {
                    if let pathElement {
                        """
                        let rawValue = try \(parentContainerVarName).decode(
                            \(field.elementEncodedType), 
                            forKey: .k\(raw: pathElement)
                        )
                        """
                    } else {
                        "let rawValue = try \(parentContainerVarName).decode(\(field.elementEncodedType))"
                    }
                    "\(sequenceDecodeTempVarName).append(rawValue)" as CodeBlockItemSyntax
                }
                let typeMismatchCatchClause = CatchClauseSyntax([
                    .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.typeMismatch" as ExprSyntax))
                ]) {
                    fieldsToInitOnError.compactMap { field in 
                        let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyName)" as TokenSyntax
                        return switch field.defaultValueOnMismatch {
                            case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                            default: nil 
                        }
                    }
                    if pathElement == nil {
                        "try \(parentContainerVarName).skip()"
                    }
                }
                let missingCatchClause = CatchClauseSyntax([
                    .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.keyNotFound" as ExprSyntax, trailingTrivia: ", ")),
                    .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.valueNotFound" as ExprSyntax))
                ]) {
                    fieldsToInitOnError.compactMap { field in 
                        let sequenceDecodeTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyName)" as TokenSyntax
                        return switch field.defaultValueOnMissing {
                            case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                            default: nil 
                        }
                    }
                    if pathElement == nil {
                        "try \(parentContainerVarName).skip()"
                    }
                }
                let catchClause = switch field.requirementStrategy {
                    case .allowAll: [missingCatchClause, typeMismatchCatchClause]
                    case .allowMismatch: [typeMismatchCatchClause]
                    case .allowMissing: [missingCatchClause]
                    case .always: []
                } as [CatchClauseSyntax]
                expr.catchClauses.append(contentsOf: catchClause)
                codeBlockItems.append(.init(item: .stmt(.init(expr))))
            } 
        }

        return (codeBlockItems, fieldsToInitOnError)

    }


    static func generateEncodeMethod(
        from structure: CodingStructure,
        inherit: Bool,
        macroNode: AttributeSyntax
    ) throws -> DeclSyntax {

        var containerStack: [TokenSyntax] = []

        func structureDfs(_ structure: CodingStructure) throws -> [CodeBlockItemSyntax] {

            var items = [CodeBlockItemSyntax]()

            switch structure {

                case let .root(children, _):
                    let containerName = "root" as TokenSyntax
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    items = try generateRootEncodeItems(
                        containerName: containerName,
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
                        parentContainerName: parentContainerName,
                        containerName: containerName,
                        pathElement: pathElement, 
                        childDecodingItems: children.values.flatMap { try structureDfs($0) }
                    )

                case let .leaf(pathElement, field):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    try items.append(field.makeEncodeBlock(containerVarName: parentContainerVarName, pathElement: pathElement))

                case let .sequenceLeaf(pathElement, fields, _): do {

                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    let unkeyedContainerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    let unkeyedContainerVarName = "\(containerVarNamePrefix)\(unkeyedContainerName)" as TokenSyntax

                    containerStack.append(unkeyedContainerName)
                    defer { containerStack.removeLast() }

                    let makeUnkeyedContainerExpr = """
                        var \(unkeyedContainerVarName) = \(parentContainerVarName).nestedUnkeyedContainer(
                            forKey: .k\(raw: pathElement)
                        )
                        """ as CodeBlockItemSyntax

                    for field in fields {

                        guard let sequenceCodingElementInfo = field.sequenceElementCodingFieldInfo else {
                            throw InternalError(message: "Missing sequence coding info for field with name \(field.propertyInfo.name)")
                        }

                        let sequenceCodingTempVarName = "\(sequenceCodingTempVarNamePrefix)\(field.propertyInfo.name)" as TokenSyntax
                        let elementToEncodeVarName = "\(sequenceCodingElementVarNamePrefix)\(field.propertyInfo.name)" as TokenSyntax

                        let transformExpr = try {
                            let closure = try ClosureExprSyntax(
                                signature: .init(
                                    parameterClause: .init(.init(leadingTrivia: " ", parameters: [], trailingTrivia: " ")), 
                                    effectSpecifiers: .init(throwsClause: .init(throwsSpecifier: .keyword(.throws)), trailingTrivia: " "),
                                    trailingTrivia: "\n"
                                )
                            ) {
                                try field.makeEncodeTransformExprs(sourceVarName: "self.\(field.propertyInfo.name)", destVarName: "transformedValue")
                                if let transformExpr = sequenceCodingElementInfo.encodeTransformExpr {
                                    "\nreturn try \(CodingFieldInfo.transformFunctionName)(transformedValue, \(transformExpr))"
                                } else {
                                    "\nreturn transformedValue"
                                }
                            }
                            return "let \(sequenceCodingTempVarName) = try \(closure)()" as CodeBlockItemSyntax
                        }()

                        let expr = try DoStmtSyntax("do") {
                            makeUnkeyedContainerExpr
                            transformExpr
                            if sequenceCodingElementInfo.path.isEmpty {
                                try ForStmtSyntax("for \(elementToEncodeVarName) in \(sequenceCodingTempVarName)") {
                                    "try \(unkeyedContainerVarName).encode(\(elementToEncodeVarName))"
                                }
                            } else {
                                try ForStmtSyntax("for \(elementToEncodeVarName) in \(sequenceCodingTempVarName)") {
                                    try generateSequenceEncodeItems(
                                        field: field, 
                                        parentUnkeyedContainerName: unkeyedContainerName, 
                                        elementToEncodeVarName: elementToEncodeVarName, 
                                        macroNode: macroNode
                                    )
                                }
                            }
                        }
                        items.append(.init(item: .stmt(.init(expr))))

                    }
                    
                }

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


    static func flattenSequenceSubStructure(
        _ structure: CodingSequenceSubStructure
    ) -> [SequenceElementCodingFieldInfo: [String]] {

        var flattened = [SequenceElementCodingFieldInfo: [String]]()

        switch structure {
            case let .root(children, _):
                for child in children.values {
                    flattened = flattenSequenceSubStructure(child)
                    for key in flattened.keys {
                        flattened[key]?.reverse()
                    }
                }
            case let .node(pathElement, children, _):
                for child in children.values {
                    let childFlattened = flattenSequenceSubStructure(child)
                    for key in childFlattened.keys {
                        flattened[key, default: []].append(pathElement)
                    }
                }
            case let .leaf(pathElement, field):
                if let pathElement {
                    flattened[field] = [pathElement]
                }
        }

        return flattened

    }


    static func generateSequenceEncodeItems(
        field: CodingFieldInfo,
        parentUnkeyedContainerName: TokenSyntax,
        elementToEncodeVarName: TokenSyntax,
        macroNode: AttributeSyntax
    ) throws -> [CodeBlockItemSyntax] {

        guard let sequenceElementCodingInfo = field.sequenceElementCodingFieldInfo else {
            throw InternalError(message: "Expected sequence element coding info")
        }

        var items = [CodeBlockItemSyntax]()

        let parentUnkeyedContainerVarName = "\(containerVarNamePrefix)\(parentUnkeyedContainerName)" as TokenSyntax
        let containerName = "\(parentUnkeyedContainerName)_root" as TokenSyntax
        let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
        let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax

        items.append("""
            var \(containerVarName) = \(parentUnkeyedContainerVarName).nestedContainer(
                keyedBy: \(containerCodingKeysName).self
            )
            """
        )

        var currentContainerName = containerName
        
        for (i, path) in sequenceElementCodingInfo.path.enumerated() {

            let parentContainerName = currentContainerName
            let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
            currentContainerName = "\(parentContainerName)_\(raw: path)" as TokenSyntax
            let containerVarName = "\(containerVarNamePrefix)\(currentContainerName)" as TokenSyntax
            let containerCodingKeysName = "\(containerCodingKeysPrefix)\(currentContainerName)" as TokenSyntax

            if i == sequenceElementCodingInfo.path.count - 1 {
                items.append("""
                    try \(parentContainerVarName).encode(
                        \(elementToEncodeVarName),
                        forKey: .k\(raw: path)
                    )
                    """
                )
            } else {
                items.append("""
                    var \(containerVarName) = \(parentContainerVarName).nestedContainer(
                        keyedBy: \(containerCodingKeysName).self,
                        forKey: .k\(raw: path)
                    )
                    """
                )
            }

        }

        return items 

    }
    
}



// MARK: Helpers for generating decode/encode blocks
extension CodableMacro {

    fileprivate static let containerCodingKeysPrefix = "$__coding_container_keys_" as TokenSyntax
    fileprivate static let containerVarNamePrefix = "$__coding_container_" as TokenSyntax
    fileprivate static let sequenceCodingTempVarNamePrefix = "$__sequence_coding_temp_" as TokenSyntax
    fileprivate static let sequenceCodingElementVarNamePrefix = "$__sequence_coding_element_" as TokenSyntax

    private static func initFieldsWithDefaultCodeBlockItems(
        _ fieldsToInitOnError: [CodingFieldInfo], 
        type: RequriementStrategy
    ) throws -> [CodeBlockItemSyntax] {

        let defaultValueKeyPath = switch type {
            case .allowMismatch: \CodingFieldInfo.defaultValueOnMisMatch
            case .allowMissing: \CodingFieldInfo.defaultValueOnMissing
            case .allowAll: throw InternalError(message: "Unexpected `.allowAll` requirement strategy when generating default value assignment")
            case .always: throw InternalError(message: "Unexpected `.always` requirement strategy when generating default value assignment")
        } as WritableKeyPath<CodableMacro.CodingFieldInfo, ExprSyntax?>

        return try fieldsToInitOnError.map { 
            if let defaultValue = $0[keyPath: defaultValueKeyPath] {
                "self.\($0.propertyInfo.name) = \(defaultValue)"
            } else if $0.propertyInfo.initializer == nil, $0.propertyInfo.hasOptionalTypeDecl {
                "self.\($0.propertyInfo.name) = nil"
            } else {
                throw .diagnostic(node: $0.propertyInfo.name, message: .codingMacro.codable.missingDefaultOrOptional)
            }
        }

    }


    private static func addCatchClauses(
        to doStmt: inout DoStmtSyntax, 
        fieldsWithDefault: [CodingFieldInfo], 
        requirementStrategy: RequriementStrategy
    ) throws {

        if requirementStrategy.allowMismatch {
            doStmt.catchClauses.append(
                try CatchClauseSyntax(
                    catchItems: [.init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.typeMismatch" as ExprSyntax))]
                ) {
                    try initFieldsWithDefaultCodeBlockItems(fieldsWithDefault, type: .allowMismatch)
                }
            )
        }

        if requirementStrategy.allowMissing {
            doStmt.catchClauses.append(
                try CatchClauseSyntax(
                    catchItems: [.init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.keyNotFound" as ExprSyntax))]
                ) {
                    try initFieldsWithDefaultCodeBlockItems(fieldsWithDefault, type: .allowMissing)
                }
            )
        }

    }


    private static func generateRootDecodeItems(
        containerName: TokenSyntax,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [CodingFieldInfo]
    ) throws -> [CodeBlockItemSyntax] {

        let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
        let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax

        var codeBlockItems = [CodeBlockItemSyntax]()

        let decodeExpr = "let \(containerVarName) = try decoder.container(keyedBy: \(containerCodingKeysName).self)" as CodeBlockItemSyntax

        if requirementStrategy == .always {
            codeBlockItems.append(decodeExpr)
            codeBlockItems.append(contentsOf: childDecodingItems)
        } else {
            var expr = try DoStmtSyntax("do") {
                decodeExpr
                childDecodingItems
            }
            try addCatchClauses(to: &expr, fieldsWithDefault: fieldsToInitOnError, requirementStrategy: requirementStrategy)
            codeBlockItems.append(.init(item: .stmt(.init(expr))))
        }

        return codeBlockItems

    }


    private static func generateContainerDecodeItems(
        parentContainerName: TokenSyntax,
        containerName: TokenSyntax,
        pathElement: String,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [CodingFieldInfo]
    ) throws -> [CodeBlockItemSyntax] {

        let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
        let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
        let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax

        var codeBlockItems = [CodeBlockItemSyntax]()

        let decodeExpr = """
            let \(containerVarName) = try \(parentContainerVarName).nestedContainer(
                keyedBy: \(containerCodingKeysName).self, 
                forKey: .k\(raw: pathElement)
            )
            """ as CodeBlockItemSyntax

        if requirementStrategy == .always {
            codeBlockItems.append(decodeExpr)
            codeBlockItems.append(contentsOf: childDecodingItems)
        } else {
            var expr = try DoStmtSyntax("do") {
                decodeExpr
                childDecodingItems
            }
            try addCatchClauses(to: &expr, fieldsWithDefault: fieldsToInitOnError, requirementStrategy: requirementStrategy)
            codeBlockItems.append(.init(item: .stmt(.init(expr))))
        }

        return codeBlockItems

    }


    private static func generateContainerEncodeItems(
        parentContainerName: TokenSyntax,
        containerName: TokenSyntax,
        pathElement: String,
        childDecodingItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {

        let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
        let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
        let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax

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
        containerName: TokenSyntax,
        childDecodingItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {
        let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
        let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax
        var codeBlockItems = [CodeBlockItemSyntax]()
        codeBlockItems.append("var \(containerVarName) = encoder.container(keyedBy: \(containerCodingKeysName).self)")
        codeBlockItems.append(contentsOf: childDecodingItems)
        return codeBlockItems
    }

}


// MARK: Helpers for generating decode/encode blocks
extension CodableMacro.CodingFieldInfo {

    static var transformFunctionName: TokenSyntax { "$__coding_transform" }
    static var validateFunctionName: TokenSyntax { "$__coding_validate" }
    static var makeEmptyArrayFunctionName: TokenSyntax { "$__coding_make_empty_array" }

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


    static var makeEmptyArrayFunctionDecl: DeclSyntax {
        """
        func \(makeEmptyArrayFunctionName)<T>(ofType type: T.Type) -> [T] {
            return []
        }
        """
    }


    func makeDecodeBlock(containerVarName: TokenSyntax, pathElement: String) throws -> CodeBlockItemSyntax {
        var doStmt = try DoStmtSyntax("do") {
            try self.makeDecodeExpr(parentContainerVarName: containerVarName, pathElement: pathElement, resultVarName: "rawValue")
            try self.makeDecodeTransformExprs(sourceVarName: "rawValue", destVarName: "value")
            try self.makeValidateionExprs(varName: "value")
            "self.\(propertyInfo.name) = value"
        } 
        if self.requirementStrategy.allowMismatch {
            doStmt.catchClauses.append(
                CatchClauseSyntax(
                    catchItems: [.init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.typeMismatch" as ExprSyntax))]
                ) {
                    if let defaultValue = self.defaultValueOnMisMatch {
                        "self.\(propertyInfo.name) = \(defaultValue)"
                    } else if self.propertyInfo.initializer == nil, self.propertyInfo.hasOptionalTypeDecl {
                        "self.\(propertyInfo.name) = nil"
                    }
                }
            )
        }
        if self.requirementStrategy.allowMissing {
            doStmt.catchClauses.append(
                CatchClauseSyntax(
                    catchItems: [
                        .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.valueNotFound" as ExprSyntax, trailingTrivia: ", ")),
                        .init(pattern: ExpressionPatternSyntax(expression: "Swift.DecodingError.keyNotFound" as ExprSyntax))
                    ]
                ) {
                    if let defaultValue = self.defaultValueOnMissing {
                        "self.\(propertyInfo.name) = \(defaultValue)"
                    } else if self.propertyInfo.initializer == nil, self.propertyInfo.hasOptionalTypeDecl {
                        "self.\(propertyInfo.name) = nil"
                    }
                }
            )
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
        return """
            let \(resultVarName) = try \(parentContainerVarName).decode(
                \(self.decodeTransform?.decodeSourceType ?? typeExpression),
                forKey: .k\(raw: pathElement)
            )
            """
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
        if let transformSpec = self.decodeTransform {
            transformSpec.transformExprs.enumerated().map { i, transform in
                let localSourceVarName = i == 0 ? sourceVarName : "value\(raw: i)" as TokenSyntax
                let localDestVarName = i == transformSpec.transformExprs.count - 1 ? destVarName : "value\(raw: i + 1)" as TokenSyntax
                return "let \(localDestVarName) = try \(Self.transformFunctionName)(\(localSourceVarName), \(transform))"
            }
        } else {
            ["let \(destVarName) = \(sourceVarName)"]
        }
    }

    
    func makeValidateionExprs(varName: TokenSyntax) throws -> [CodeBlockItemSyntax] {
        self.validateExprs.map { expr in
            let exprString = StringLiteralExprSyntax(content: IndentRemover().visit(expr).formatted().description)
            return #"try \#(Self.validateFunctionName)("\#(propertyInfo.name)", \#(exprString), \#(varName), \#(expr))"#
        }
    }

}