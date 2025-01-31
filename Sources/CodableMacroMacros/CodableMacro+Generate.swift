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
    
    
    
    static func generateEnumDeclarations(from declSpecList: [EnumDeclSpec]) -> [DeclSyntax] {
        
        declSpecList.map { decl in
            """
            enum \(decl.name): String, CodingKey {
                case \(raw: decl.cases.map({ #"k\#($0) = "\#($0)""# }).joined(separator: ","))
            }
            """
        }
        
    }
    
    
    static func generateDecodeInitializer(
        from steps: [CodingStep],
        isClass: Bool,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // helper functions for decoding that does not reuqire providing the type
        let decodeFunctionName = context.makeUniqueName("decode")
        let decodeIfPresentFunctionName = context.makeUniqueName("decodeIfPresent")
        
        func generateDecodeInitializerBody<C: BidirectionalCollection & RangeReplaceableCollection>(
            from steps: inout C
        ) throws -> [CodeBlockItemSyntax] where C.Element == CodingStep {
            
            var codeBlockItems = [CodeBlockItemSyntax]()
            
            while let step = steps.popLast() {
                
                switch step {
                    
                    // a container step with a required parent container
                    case let .container(container, .some(parentContainer)) where container.isRequired:
                        codeBlockItems.append("""
                            let \(container.name) = try \(parentContainer.name).nestedContainer(
                                keyedBy: \(container.keysDef).self, 
                                forKey: .\(raw: parentContainer.key)
                            )
                            """
                        )
                    
                    // a container step with a non-required parent container
                    case let .container(container, .some(parentContainer)):
                        // finding fields that require initialization in the else branch
                        var valueStepsWithDefault: [CodingFieldInfo] = []
                        var count = 1
                        for operation in steps.reversed() where count > 0 {
                            switch operation {
                                case let .container(container, _) where !container.isRequired:
                                    count += 1
                                case .endOptionalContainer:
                                    count -= 1
                                case let .value(info, _) where info.defaultValue != nil :
                                    valueStepsWithDefault.append(info)
                                case let .value(info, _) where info.propertyInfo.initializer == nil && info.propertyInfo.hasOptionalTypeDecl:
                                    valueStepsWithDefault.append(info)
                                default: break
                            }
                        }
                        // for non-required container, only decode them when they actually exist
                        // the else branch is for initializing fields with macro-level default values
                        let expr = try IfExprSyntax("if \(parentContainer.name).contains(.\(raw: parentContainer.key))") {
                            """
                            let \(container.name) = try \(parentContainer.name).nestedContainer(
                                keyedBy: \(container.keysDef).self,
                                forKey: .\(raw: parentContainer.key)
                            )
                            """
                            try generateDecodeInitializerBody(
                                from: &steps
                            )
                        } else: {
                            try valueStepsWithDefault.map {
                                if let defaultValue = $0.defaultValue {
                                    "self.\($0.propertyInfo.name) = \(defaultValue)"
                                } else if $0.propertyInfo.initializer == nil, $0.propertyInfo.hasOptionalTypeDecl {
                                    "self.\($0.propertyInfo.name) = nil"
                                } else {
                                    throw .diagnostic(node: $0.propertyInfo.name, message: Error.missingDefaultOrOptional)
                                }
                            }
                        }
                        codeBlockItems.append(.init(item: .expr(.init(expr))))
                        
                    // container step with no parent (the root container)
                    case let .container(container, .none):
                        codeBlockItems.append(
                            "let \(container.name) = try decoder.container(keyedBy: \(container.keysDef).self)"
                        )
                        
                    // step that mark the end of an not-required container step
                    case .endOptionalContainer:
                        return codeBlockItems
                        
                    // a value step that actually decode the value of a property
                    case let .value(codingFieldInfo, parentContainer):
                        let propertyInfo = codingFieldInfo.propertyInfo
                        guard propertyInfo.type != .constant || propertyInfo.initializer == nil else {
                            // a let constant with an initializer cannot be decoded, ignore it
                            break
                        }
                        let newItem = if let defaultValue = codingFieldInfo.defaultValue {
                            // has macro-level default value
                            """
                            self.\(propertyInfo.name) = try Self.\(decodeIfPresentFunctionName)(
                                container: \(parentContainer.name), 
                                key: .\(raw: parentContainer.key)
                            ) ?? \(defaultValue)
                            """
                        } else if propertyInfo.initializer != nil {
                            // no macro-level default, but has initializer
                            """
                            if \(parentContainer.name).contains(.\(raw: parentContainer.key)) {
                                self.\(propertyInfo.name) = try Self.\(decodeFunctionName)(
                                    container: \(parentContainer.name), 
                                    key: .\(raw: parentContainer.key)
                                ) 
                            }
                            """
                        } else if propertyInfo.hasOptionalTypeDecl {
                            // no macro-level default or initializer, but is optional
                            """
                            self.\(propertyInfo.name) = try Self.\(decodeIfPresentFunctionName)(
                                container: \(parentContainer.name),
                                key: .\(raw: parentContainer.key)
                            )
                            """
                        } else {
                            // a required property (no default, no initializer, not optional)
                            """
                            self.\(propertyInfo.name) = try Self.\(decodeFunctionName)(
                                container: \(parentContainer.name), 
                                key: .\(raw: parentContainer.key)
                            )
                            """
                        } as CodeBlockItemSyntax
                        codeBlockItems.append(newItem)
                        
                }
                
            }
            
            return codeBlockItems
            
        }
        
        var steps = steps
        steps.reverse()        // process from the end, which should be more efficient for array
        
        return [
            
            """
            private static func \(decodeFunctionName)<R: Decodable, C: CodingKey>(container: KeyedDecodingContainer<C>, key: C) throws -> R {
                try container.decode(R.self, forKey: key)
            }
            """ as DeclSyntax,
            
            """
            private static func \(decodeFunctionName)<R: Decodable, C: CodingKey>(container: KeyedDecodingContainer<C>?, key: C) throws -> R? {
                try container?.decode(R.self, forKey: key)
            }
            """ as DeclSyntax,
            
            """
            private static func \(decodeIfPresentFunctionName)<R: Decodable, C: CodingKey>(container: KeyedDecodingContainer<C>, key: C) throws -> R? {
                try container.decodeIfPresent(R.self, forKey: key)
            }
            """ as DeclSyntax,
            
            """
            private static func \(decodeIfPresentFunctionName)<R: Decodable, C: CodingKey>(container: KeyedDecodingContainer<C>?, key: C) throws -> R? {
                try container?.decodeIfPresent(R.self, forKey: key)
            }
            """ as DeclSyntax,
            
            .init(
                try InitializerDeclSyntax("public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws") {
                    try generateDecodeInitializerBody(from: &steps)
                }
            )
            
        ]
        
    }
    
    
    static func generateEncodeMethod(from steps: [CodingStep]) throws -> DeclSyntax {
        
        let decl = try FunctionDeclSyntax("public func encode(to encoder: Encoder) throws") {
            
            steps.compactMap { step in
                
                switch step {
                    // container step with parent container
                    case let .container(container, .some(parentContainer)):
                        """
                        var \(container.name) = \(parentContainer.name).nestedContainer(
                            keyedBy: \(container.keysDef).self, 
                            forKey: .\(raw: parentContainer.key)
                        )
                        """
                    // container step with no parent container (the root container)
                    case let .container(container, .none):
                        """
                        var \(container.name) = encoder.container(keyedBy: \(container.keysDef).self)
                        """
                    // step representing the end of a not-required container
                    case .endOptionalContainer:
                        nil
                    // value step of optional properties
                    case let .value(codingFieldInfo, parentContainer) where codingFieldInfo.propertyInfo.hasOptionalTypeDecl:
                        """
                        if self.\(codingFieldInfo.propertyInfo.name) != nil {
                            try \(parentContainer.name).encode(self.\(codingFieldInfo.propertyInfo.name), forKey: .\(raw: parentContainer.key))
                        }
                        """
                    // value step of non optional properties
                    case let .value(codingFieldInfo, parentContainer):
                        """
                        try \(parentContainer.name).encode(self.\(codingFieldInfo.propertyInfo.name), forKey: .\(raw: parentContainer.key))
                        """
                }
                
            }
            
        }
        
        return .init(decl)
        
    }
    
}
