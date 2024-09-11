//
//  CodableMacro+Helpers.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/9.
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


    
    enum CodingOperation {
        case container(keysDef: TokenSyntax, parent: (container: TokenSyntax, key: String)?)
        case optionalContainer(keysDef: TokenSyntax, parent: (container: TokenSyntax, key: String))
        case endOptionalContainer
        case code(container: TokenSyntax, key: String, field: CodingFieldMacro.FieldInfo)
    }
    
    
    
    static func extractCodingFieldInfoList(
        from members: MemberBlockItemListSyntax,
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> [CodingFieldMacro.CodingFieldInfo] {
        
        try members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { member in
                !member.attributes.contains {
                    $0.as(AttributeSyntax.self)?.attributeName
                        .as(IdentifierTypeSyntax.self)?.name.trimmed.text == "CodingIgnore"
                }
            }
            .map { (member) throws(DiagnosticsError) in
                let codingFieldAttributes = member.attributes
                    .compactMap { $0.as(AttributeSyntax.self) }
                    .filter {
                        $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text == "CodingField"
                    }
                guard codingFieldAttributes.count < 2 else {
                    throw .diagnostic(node: member, message: Error.multipleCodingField)
                }
                return if let codingFieldAttribute = codingFieldAttributes.first {
                    try CodingFieldMacro.processCodingField(member, macroNode: codingFieldAttribute)
                } else {
                    try CodingFieldMacro.processDefaultField(member)
                }
            }
            .compactMap { $0 }
        
    }
    
    
    
    static func buildOperations(
        from structure: CodingStructure,
        context: some MacroExpansionContext,
        macroNode: AttributeSyntax
    ) throws(DiagnosticsError) -> (enumDecls: [EnumDeclSpec], operations: [CodingOperation]) {
        
        var enumDeclList = [EnumDeclSpec]()
        var operations = [CodingOperation]()
        var enumStack = [TokenSyntax]()
        var pathStack = [String]()
        
        func codingStructureDfs(_ structure: borrowing CodingStructure) throws(DiagnosticsError) {
            
            switch structure {
                    
                case .root(let children):
                    let newEnum = EnumDeclSpec(
                        name: context.makeUniqueName("root"),
                        cases: children.values.compactMap { $0.pathElement }
                    )
                    enumDeclList.append(newEnum)
                    enumStack.append(newEnum.name)
                    operations.append(.container(keysDef: newEnum.name, parent: nil))
                    for child in children.values {
                        try codingStructureDfs(child)
                    }
                    enumStack.removeLast()
                    
                case .node(let pathElement, let children, let required):
                    guard let parentContainer = enumStack.last else {
                        throw .diagnostic(node: macroNode, message: Error.unexpectedEmptyEnumStack)
                    }
                    pathStack.append(pathElement)
                    let newEnum = EnumDeclSpec(
                        name: context.makeUniqueName(pathStack.joined()),
                        cases: children.values.compactMap { $0.pathElement }
                    )
                    enumDeclList.append(newEnum)
                    enumStack.append(newEnum.name)
                    if required {
                        operations.append(
                            .container(keysDef: newEnum.name, parent: (container: parentContainer, key: pathElement))
                        )
                    } else {
                        operations.append(
                            .optionalContainer(keysDef: newEnum.name, parent: (container: parentContainer, key: pathElement))
                        )
                    }
                    for child in children.values {
                        try codingStructureDfs(child)
                    }
                    if !required {
                        operations.append(.endOptionalContainer)
                    }
                    pathStack.removeLast()
                    enumStack.removeLast()
                    
                case .leaf(let pathElement, let field):
                    guard let parentContainer = enumStack.last else {
                        throw .diagnostic(node: macroNode, message: Error.unexpectedEmptyEnumStack)
                    }
                    operations.append(
                        .code(container: parentContainer, key: pathElement, field: field)
                    )
                    
            }
            
        }
        
        try codingStructureDfs(structure)
        
        return (enumDeclList, operations)
        
    }
    
    
    static func generateEnumDeclarations(from declSpecList: [EnumDeclSpec]) -> [DeclSyntax] {
        
        declSpecList.map { decl in
            """
            enum \(decl.name): String, CodingKey {
                case \(raw: decl.cases.joined(separator: ","))
            }
            """
        }
        
    }
    
    
    static func generateDecodeInitializer(
        from operations: [CodingOperation],
        context: some MacroExpansionContext
    ) throws -> [any DeclSyntaxProtocol] {
        
        let decodeFunctionName = context.makeUniqueName("decode")
        let decodeIfPresentFunctionName = context.makeUniqueName("decodeIfPresent")
        
        func generateDecodeInitializerBody<C: BidirectionalCollection & RangeReplaceableCollection>(
            from operations: inout C
        ) throws -> [CodeBlockItemSyntax] where C.Element == CodingOperation {
            
            var codeBlockItems = [CodeBlockItemSyntax]()
            
            while let operation = operations.popLast() {
                
                switch operation {
                        
                    case let .container(keysDef, .some((container, key))):
                        codeBlockItems.append("""
                        let \(keysDef)container = try \(container)container.nestedContainer(
                            keyedBy: \(keysDef).self, 
                            forKey: .\(raw: key)
                        )
                        """
                        )
                        
                    case let .container(keysDef, .none):
                        codeBlockItems.append(
                            "let \(keysDef)container = try decoder.container(keyedBy: \(keysDef).self)"
                        )
                        
                    case let .optionalContainer(keysDef, (container, key)):
                        let ifExpr = try IfExprSyntax("if \(container)container.contains(.\(raw: key))") {
                            """
                            let \(keysDef)container = try \(container)container.nestedContainer(
                                keyedBy: \(keysDef).self, 
                                forKey: .\(raw: key)
                            )
                            """
                            try generateDecodeInitializerBody(from: &operations)
                        }
                        codeBlockItems.append(.init(item: .expr(.init(ifExpr))))
                        
                    case .endOptionalContainer:
                        return codeBlockItems
                        
                    case let .code(container, key, field):
                        let newItem = if field.canInit {
                            if let defaultValue = field.defaultValue {
                                """
                                self.\(field.name) = try Self.\(decodeIfPresentFunctionName)(
                                    container: \(container)container, 
                                    key: .\(raw: key)
                                ) ?? \(defaultValue)
                                """
                            } else if field.isOptional {
                                """
                                self.\(field.name) = try Self.\(decodeIfPresentFunctionName)(
                                    container: \(container)container, 
                                    key: .\(raw: key)
                                )
                                """
                            } else {
                                """
                                self.\(field.name) = try Self.\(decodeFunctionName)(
                                    container: \(container)container, 
                                    key: .\(raw: key)
                                )
                                """
                            }
                        } else {
                            ""
                        } as CodeBlockItemSyntax
                        codeBlockItems.append(newItem)
                        
                }
                
            }
            
            return codeBlockItems
            
        }
        
        var operations = operations
        operations.reverse()
        
        return [
            
            """
            private static func \(decodeFunctionName)<R: Decodable, C: CodingKey>(container: KeyedDecodingContainer<C>, key: C) throws -> R {
                try container.decode(R.self, forKey: key)
            }
            """ as DeclSyntax,
            
            """
            private static func \(decodeIfPresentFunctionName)<R: Decodable, C: CodingKey>(container: KeyedDecodingContainer<C>, key: C) throws -> R? {
                try container.decodeIfPresent(R.self, forKey: key)
            }
            """ as DeclSyntax,
            
            try InitializerDeclSyntax("public init(from decoder: Decoder) throws") {
                try generateDecodeInitializerBody(from: &operations)
            }
            
        ]
        
    }
    
    
    static func generateEncodeMethod(from operations: [CodingOperation]) throws -> FunctionDeclSyntax {
        
        try .init("public func encode(to encoder: Encoder) throws") {
            
            operations.map { operation in
                
                switch operation {
                    case let .container(keysDef, .some((container, key))):
                        """
                        var \(keysDef)container = \(container)container.nestedContainer(
                            keyedBy: \(keysDef).self, 
                            forKey: .\(raw: key)
                        )
                        """
                    case let .optionalContainer(keysDef, (container, key)):
                        """
                        var \(keysDef)container = \(container)container.nestedContainer(
                            keyedBy: \(keysDef).self, 
                            forKey: .\(raw: key)
                        )
                        """
                    case .endOptionalContainer:
                        ""
                    case let .container(keysDef, .none):
                        """
                        var \(keysDef)container = encoder.container(keyedBy: \(keysDef).self)
                        """
                    case let .code(container, key, field):
                        """
                        try \(container)container.encode(self.\(field.name), forKey: .\(raw: key))
                        """
                }
                
            }
            
        }
        
    }
    
}
