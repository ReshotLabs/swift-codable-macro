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


struct SingleValueCodableMacro: CodingImplMacroProtocol {
    
    static let supportedAttachedTypes: Set<AttachedType> = [.class, .struct]
    
    
    static func makeExtensionHeader(
        node: AttributeSyntax,
        type: some TypeSyntaxProtocol,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> SyntaxNodeString {
        return "extension \(type): SingleValueCodableProtocol"
    }
    
    
    static func makeDecls(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let declGroupInfo = try DeclGroupSyntaxInfo.extract(from: declaration)
        
        let isClass = declGroupInfo.type == .class
        let allProperties = declGroupInfo.properties
        
        var shouldAutoInit: Bool {
            isClass
            && !allProperties.contains(where: \.isRequired)     // all stored properties are initialized
            && !declGroupInfo.hasInitializer                    // has no initializer
        }
        
        let delegateProperties = try allProperties
            .filter { propertyInfo in
                let delegateAttributes = propertyInfo.attributes.filter {
                    guard let name = $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text else {
                        return false
                    }
                    return DecoratorMacros(rawValue: name) == .singleValueCodableDelegate
                }
                guard !delegateAttributes.isEmpty else { return false }
                try SingleValueCodableDelegateMacro.processProperty(propertyInfo, macroNodes: delegateAttributes)
                return !delegateAttributes.isEmpty
            }
        
        guard delegateProperties.count < 2 else {
            throw .diagnostic(node: declaration, message: .codingMacro.singleValueCodable.multipleDelegates)
        }
        
        guard let delegateProperty = delegateProperties.first else {
            return []
        }
        
        let requiredProperties = Set(allProperties.filter(\.isRequired).map(\.name)).subtracting([delegateProperty.name])
        guard requiredProperties.isEmpty else {
            throw .diagnostics(
                requiredProperties.map { .init(node: $0, message: .codingMacro.singleValueCodable.unhandledRequiredProperties) }
            )
        }
        
        guard let typeExpr = delegateProperty.dataType else {
            throw .diagnostic(node: delegateProperty.name, message: .codingMacro.general.missingExplicitType)
        }
        
        let defaultValue = if let initializer = delegateProperty.initializer {
            initializer
        } else if delegateProperty.hasOptionalTypeDecl {
            "nil as \(typeExpr)" as ExprSyntax
        } else {
            nil as ExprSyntax?
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
        
        if let defaultValue {
            decls.append("public static var singleValueCodingDefaultValue: \(typeExpr)? { \(defaultValue) }")
        }
        
        if shouldAutoInit {
            decls.append("public init() {}")
        }
        
        return decls
        
    }
    
    
    
    enum Error {
        
        static let multipleDelegates: CodingMacroDiagnosticMessage = .init(
            id: "multiple_delegates",
            message: "A Type for SingleValueCodable should has no more than one stored property with SingleValueCodableDelegate"
        )
        
        static let unhandledRequiredProperties: CodingMacroDiagnosticMessage = .init(
            id: "unhandled_required_properties",
            message: "This property must be initialized in the decode initializer, which can't be done due to the property with SingleValueCodableDelegate"
        )
        
    }
    
}



extension CodingMacroDiagnosticMessageGroup {
    static var singleValueCodable: SingleValueCodableMacro.Error.Type {
        SingleValueCodableMacro.Error.self
    }
}
