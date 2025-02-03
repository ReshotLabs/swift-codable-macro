//
//  SingleValueCodableMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/2.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct SingleValueCodableMacro: ExtensionMacro, MemberMacro {
    
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        return if declaration.is(ClassDeclSyntax.self) {
            [try .init("extension \(type.trimmed): SingleValueCodableProtocol", membersBuilder: {})]
        } else if declaration.is(StructDeclSyntax.self) {
            [
                try .init("extension \(type.trimmed): SingleValueCodableProtocol") {
                    try makeDecls(declaration: declaration, context: context)
                }
            ]
        } else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
    }
    
    
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        return if declaration.is(ClassDeclSyntax.self) {
            try makeDecls(declaration: declaration, context: context)
        } else if declaration.is(StructDeclSyntax.self) {
            []
        } else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
    }
    
    
    static func makeDecls(
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let isClass = declaration.is(ClassDeclSyntax.self)
        
        let allProperties = try declaration.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .map(PropertyInfo.extract(from:))
        
        var shouldAutoInit: Bool {
            isClass
            && !allProperties.contains(where: { $0.isRequired })   // all stored properties are initialized
            && !declaration.memberBlock.members.contains(where: { $0.decl.is(InitializerDeclSyntax.self) })     // has no initializer
        }
        
        let delegateProperties = try allProperties
            .filter { propertyInfo in
                let delegateAttributes = propertyInfo.attributes.filter {
                    guard let name = $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text else {
                        return false
                    }
                    return DecoratorMacros(rawValue: name) == .singleValueCodableDelegate
                }
                try SingleValueCodableDelegateMacro.processProperty(propertyInfo, macroNodes: delegateAttributes)
                return !delegateAttributes.isEmpty
            }
        
        guard delegateProperties.count < 2 else {
            throw .diagnostic(node: declaration, message: Error.multipleDelegates)
        }
        
        guard let delegateProperty = delegateProperties.first else {
            return []
        }
        
        let requiredProperties = Set(allProperties.filter(\.isRequired).map(\.name)).subtracting([delegateProperty.name])
        
        guard requiredProperties.isEmpty else {
            throw .diagnostics(
                requiredProperties.map { .init(node: $0, message: Error.unhandledRequiredProperties) }
            )
        }
        
        guard let typeExpr = delegateProperty.dataType else {
            throw .diagnostic(node: delegateProperty.name, message: Error.cannotInferType)
        }
        
        let canDecode = delegateProperty.type != .constant || delegateProperty.initializer == nil
        
        var decls = [
            """
            public func singleValueEncode() throws -> \(typeExpr) {
                return self.\(delegateProperty.name)
            }
            """,
            """
            public \(raw: isClass ? "required " : "")init(from codingValue: \(typeExpr)) throws {
                \(canDecode ? "self.\(delegateProperty.name) = codingValue" : "")
            }
            """
        ] as [DeclSyntax]
        
        if shouldAutoInit {
            decls.append("public init() {}")
        }
        
        return decls
        
    }
    
    
    enum Error: String, DiagnosticMessage {
        
        case attachTypeError = "attach_type"
        case noIdentifierFound = "no_identifier"
        case multipleDelegates = "multiple_delegates"
        case unexpectedEmptyContainerStack = "unexpected_empty_container_stack"
        case missingDefaultOrOptional = "missing_default_or_optional"
        case cannotInferType = "cannot_infer_type"
        case unhandledRequiredProperties = "unhandled_required_properties"
        
        
        var message: String {
            switch self {
                case .attachTypeError: "The Codable macro can only be applied to class or struct declaration"
                case .noIdentifierFound: "The Codable macro can only be applied to class or struct declaration"
                case .multipleDelegates: "A Type for SingleValueCodable should has no more than one stored property with SingleValueCodableDelegate"
                case .unexpectedEmptyContainerStack: "Internal Error: unexpected empty container stack"
                case .missingDefaultOrOptional: "Internal Error: missing macro-level default or optional mark, which should have been filtered out"
                case .cannotInferType: "Expect explicit type annotation for the stored property with SingleValueCodableDelegate"
                case .unhandledRequiredProperties: "This property must be initialized in the decode initializer, which can't be done due to the property with SingleValueCodableDelegate"
            }
        }
        
        var diagnosticID: SwiftDiagnostics.MessageID {
            .init(domain: "com.serika.codable_macro.codable", id: self.rawValue)
        }
        
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
        
    }
    
}
