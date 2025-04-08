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

    static func generateEncodeMethod(
        from structure: CodingStructure,
        inherit: Bool
    ) throws -> DeclSyntax {

        var containerStack: [CodingContainerName] = []

        func structureDfs(_ structure: CodingStructure) throws -> [CodeBlockItemSyntax] {

            var items = [CodeBlockItemSyntax]()

            switch structure {

                case let .root(children, _):
                    let container = "root" as CodingContainerName
                    containerStack.append(container)
                    defer { containerStack.removeLast() }
                    items = try generateRootEncodeItems(
                        container: container,
                        childDecodingItems: children.values.flatMap { try structureDfs($0) }
                    )

                case let .node(pathElement, children, _):
                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    let container = parentContainer.childContainer(with: pathElement)
                    containerStack.append(container)
                    defer { containerStack.removeLast() }
                    items = try generateContainerEncodeItems(
                        parentContainer: parentContainer,
                        pathElement: pathElement, 
                        childDecodingItems: children.values.flatMap { try structureDfs($0) }
                    )

                case let .leaf(pathElement, field):
                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    try items.append(generateEncodeBlock(field: field, container: parentContainer, pathElement: pathElement))

                case let .sequenceLeaf(pathElement, fields, _): do {

                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    let unkeyedContainer = parentContainer.childContainer(with: pathElement)

                    containerStack.append(unkeyedContainer)
                    defer { containerStack.removeLast() }

                    items = try fields.flatMap { field in
                        
                        guard let sequenceCodingElementInfo = field.sequenceCodingFieldInfo else {
                            throw InternalError(message: "Missing sequence coding info for field with name \(field.propertyInfo.name)")
                        }

                        return try generateSequenceLeafEncodeItems(
                            parentContainer: parentContainer, 
                            pathElement: pathElement, 
                            field: field, 
                            sequenceEncodeItems: generateSequenceEncodeItems(
                                sequenceElementCodingInfo: sequenceCodingElementInfo, 
                                parentUnkeyedContainer: unkeyedContainer
                            )
                        )

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
                GenerationItems.transformFunctionDecl
                try structureDfs(structure)
            }
        )

    }


    static func generateSequenceEncodeItems(
        sequenceElementCodingInfo: SequenceCodingFieldInfo,
        parentUnkeyedContainer: CodingContainerName
    ) throws -> [CodeBlockItemSyntax] {

        let elementToEncodeVarName = GenerationItems.sequenceCodingElementVarName(of: sequenceElementCodingInfo.propertyName)

        guard !sequenceElementCodingInfo.path.isEmpty else {
            return [
                GenerationItems.encodeExpr(unkeyedContainer: parentUnkeyedContainer, value: "\(elementToEncodeVarName)")
            ]
        }

        var items = [CodeBlockItemSyntax]()
        let container = parentUnkeyedContainer.childContainer(with: "root")

        items.append(GenerationItems.encodeNestedContainerStmt(parentUnkeyedContainer: parentUnkeyedContainer))

        var currentContainer = container
        
        for (i, path) in sequenceElementCodingInfo.path.enumerated() {

            let parentContainer = currentContainer
            currentContainer = parentContainer.childContainer(with: path)

            if i == sequenceElementCodingInfo.path.count - 1 {
                items.append(GenerationItems.encodeExpr(container: parentContainer, pathElement: path, value: "\(elementToEncodeVarName)"))
            } else {
                items.append(GenerationItems.encodeNestedContainerStmt(parentContainer: parentContainer, pathElement: path))
            }

        }

        return items 

    }
    
}



extension CodableMacro {

    fileprivate static func generateContainerEncodeItems(
        parentContainer: CodingContainerName,
        pathElement: String,
        childDecodingItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {

        var codeBlockItems = [CodeBlockItemSyntax]()

        codeBlockItems.append(GenerationItems.encodeNestedContainerStmt(parentContainer: parentContainer, pathElement: pathElement))
        codeBlockItems.append(contentsOf: childDecodingItems)

        return codeBlockItems

    }


    fileprivate static func generateRootEncodeItems(
        container: CodingContainerName,
        childDecodingItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {
        var codeBlockItems = [CodeBlockItemSyntax]()
        codeBlockItems.append(GenerationItems.encodeNestedContainerStmt(container: container))
        codeBlockItems.append(contentsOf: childDecodingItems)
        return codeBlockItems
    }


    fileprivate static func generateEncodeBlock(field: CodingFieldInfo, container: CodingContainerName, pathElement: String) throws -> CodeBlockItemSyntax {
        if field.propertyInfo.hasOptionalTypeDecl {
            let expr = try IfExprSyntax("if let value = self.\(field.propertyInfo.name)") {
                try makeEncodeTransformExprs(field: field, sourceVarName: "value", destVarName: "transformedValue")
                GenerationItems.encodeExpr(container: container, pathElement: pathElement, value: "transformedValue")
            }
            return .init(item: .expr(.init(expr)))
        } else {
            let expr = try DoStmtSyntax("do") {
                try self.makeEncodeTransformExprs(field: field, sourceVarName: "self.\(field.propertyInfo.name)", destVarName: "transformedValue")
                GenerationItems.encodeExpr(container: container, pathElement: pathElement, value: "transformedValue")
            }
            return .init(item: .stmt(.init(expr)))
        }
    }


    fileprivate static func generateSequenceLeafEncodeItems(
        parentContainer: CodingContainerName,
        pathElement: String,
        field: CodingFieldInfo,
        sequenceEncodeItems: [CodeBlockItemSyntax]
    ) throws -> [CodeBlockItemSyntax] {

        var items = [CodeBlockItemSyntax]()

        guard let sequenceCodingElementInfo = field.sequenceCodingFieldInfo else {
            throw InternalError(message: "Missing sequence coding info for field with name \(field.propertyInfo.name)")
        }

        let sequenceCodingTempVarName = GenerationItems.sequenceCodingTempVarName(of: field.propertyInfo.name)
        let elementToEncodeVarName = GenerationItems.sequenceCodingElementVarName(of: field.propertyInfo.name)

        let transformExpr = try {
            let closure = try ClosureExprSyntax(
                signature: .init(
                    parameterClause: .init(.init(leadingTrivia: " ", parameters: [], trailingTrivia: " ")), 
                    effectSpecifiers: .init(throwsClause: .init(throwsSpecifier: .keyword(.throws)), trailingTrivia: " "),
                    trailingTrivia: "\n"
                )
            ) {
                try makeEncodeTransformExprs(field: field, sourceVarName: "self.\(field.propertyInfo.name)", destVarName: "transformedValue")
                "\nreturn \(GenerationItems.makeSingleTransformExpr(source: "transformedValue", transform: sequenceCodingElementInfo.encodeTransformExpr))"
            }
            return "let \(sequenceCodingTempVarName) = try \(closure)()" as CodeBlockItemSyntax
        }()

        let expr = try DoStmtSyntax("do") {
            GenerationItems.encodeNestedUnkeyedContainerStmt(parentContainer: parentContainer, pathElement: pathElement)
            transformExpr
            try ForStmtSyntax("for \(elementToEncodeVarName) in \(sequenceCodingTempVarName)") {
                sequenceEncodeItems
            }
        }
        items.append(.init(item: .stmt(.init(expr))))

        return items

    }

}



extension CodableMacro {

    fileprivate static func makeEncodeTransformExprs(field: CodingFieldInfo, sourceVarName: TokenSyntax, destVarName: TokenSyntax) throws -> [CodeBlockItemSyntax] {
        guard let transformExprs = field.encodeTransform else { 
            return ["let \(destVarName) = \(sourceVarName)"] 
        }
        return transformExprs.enumerated().map { i, transform in
            let localSourceVarName = i == 0 ? sourceVarName : "value\(raw: i)" as TokenSyntax
            let localDestVarName = i == transformExprs.count - 1 ? destVarName : "value\(raw: i + 1)" as TokenSyntax
            return GenerationItems.makeSingleTransformStmt(source: localSourceVarName, transform: transform, target: localDestVarName)
        }
    }

}