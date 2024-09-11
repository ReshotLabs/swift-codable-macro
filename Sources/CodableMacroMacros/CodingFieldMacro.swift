//
//  CodingFieldMacro.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/7.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation



public struct CodingFieldMacro: PeerMacro {
    
    struct CodingFieldInfo {
        
        let field: FieldInfo
        let path: [String]
        
        init(
            fieldName: TokenSyntax,
            path: [String],
            defaultValue: ExprSyntax? = nil,
            isOptional: Bool = false,
            canInit: Bool = false
        ) {
            self.field = .init(
                name: fieldName,
                defaultValue: defaultValue,
                isOptional: isOptional,
                canInit: canInit
            )
            self.path = path
        }
        
    }
    
    
    struct FieldInfo {
        let name: TokenSyntax
        private(set) var defaultValue: ExprSyntax? = nil
        private(set) var isOptional: Bool = false
        private(set) var canInit: Bool = false
        var isRequired: Bool { (defaultValue == nil) && !isOptional }
    }
    
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        []
    }
    
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .varArg(canIgnore: true), .labeled("default", canIgnore: true)
    ]
    
    
    static func processCodingField(
        _ declaration: some SwiftSyntax.DeclSyntaxProtocol,
        macroNode: SwiftSyntax.AttributeSyntax
    ) throws(DiagnosticsError) -> CodingFieldInfo? {
        
        guard let declaration = declaration.as(VariableDeclSyntax.self) else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
        guard let fieldName = declaration.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw .diagnostic(node: declaration, message: Error.noIdentifierFound)
        }
        
        // if there is not arguments, simply delegate to the function for processing
        // properties with no `CodingField` macro
        guard
            let macroRawArguments = macroNode.arguments?.as(LabeledExprListSyntax.self),
            macroRawArguments.isEmpty == false
        else {
            return try processDefaultField(declaration)
        }
        
        guard isStoredProperty(declaration.bindings.first!) else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
        let (pathElements, defaultValue) = try extractPathAndDefault(from: macroRawArguments)
        
        var initializerExpr: ExprSyntax? { declaration.bindings.first?.initializer?.value }
        var isOptional: Bool {
            declaration.bindings.first?.typeAnnotation?.type.is(OptionalTypeSyntax.self) == true
        }
        var isLetConstant: Bool { declaration.bindingSpecifier.trimmedDescription == "let" }
        
        return .init(
            fieldName: fieldName,
            path: pathElements ?? [fieldName.trimmed.text],
            defaultValue: defaultValue ?? initializerExpr,
            isOptional: isOptional,
            canInit: !(isLetConstant && initializerExpr != nil)
        )
        
    }
    
    
    static func processDefaultField(
        _ declaration: some SwiftSyntax.DeclSyntaxProtocol
    ) throws(DiagnosticsError) -> CodingFieldInfo? {
        
        guard let declaration = declaration.as(VariableDeclSyntax.self) else { return nil }
        
        guard let fieldName = declaration.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw .diagnostic(node: declaration, message: Error.noIdentifierFound)
        }
        
        let path = [fieldName.text]
        let defaultValue = declaration.bindings.first?.initializer?.value
        var isOptional: Bool {
            declaration.bindings.first?.typeAnnotation?.type.is(OptionalTypeSyntax.self) == true
        }
        
        guard isStoredProperty(declaration.bindings.first!) else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
        var hasInitializer: Bool { declaration.bindings.first?.initializer != nil }
        var isLetConstant: Bool { declaration.bindingSpecifier.trimmedDescription == "let" }
        
        return .init(
            fieldName: fieldName,
            path: path,
            defaultValue: defaultValue,
            isOptional: isOptional,
            canInit: !(isLetConstant && hasInitializer)
        )
        
    }
    
    
    static func extractPathAndDefault(
        from macroArguments: LabeledExprListSyntax
    ) throws(DiagnosticsError) -> (pathElements: [String]?, defaultValue: ExprSyntax?) {
        
        let arguments = try macroArguments.grouped(with: macroArgumentsParsingRule)
        
        let pathElements = if arguments[0].isEmpty {
            nil as [String]?
        } else {
            arguments[0].compactMap {
                $0.expression.as(StringLiteralExprSyntax.self)?.segments.description
            }
        }
        let defaultValue = arguments[1].first?.expression
        
        guard (pathElements?.count ?? 0) == arguments[0].count else {
            throw .diagnostic(node: macroArguments, message: Error.notStringLiteral)
        }
        
        return (pathElements, defaultValue)
        
    }
    
    
    static func isStoredProperty(_ patternBindingSyntax: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = patternBindingSyntax.accessorBlock else {
            return true
        }
        guard let accessorDeclList = accessorBlock.accessors.as(AccessorDeclListSyntax.self) else {
            return false
        }
        return !accessorDeclList.lazy
            .map { $0.accessorSpecifier.trimmed }
            .contains { $0 == "set" || $0 == "get"}
    }
    
    
    
    enum Error: String, LocalizedError, DiagnosticMessage {
        
        case attachTypeError = "attach_type"
        case noIdentifierFound = "no_identifier"
        case notStringLiteral = "not_string_literal"
        
        
        var message: String {
            switch self {
                case .attachTypeError: "The CodingField macro can only be applied to stored properties"
                case .noIdentifierFound: "The CodingField macro can only be applied to stored properties"
                case .notStringLiteral: "The path can be specified using string literal"
            }
        }
        
        var diagnosticID: SwiftDiagnostics.MessageID {
            .init(domain: "com.serika.codable_macro.coding_field", id: self.rawValue)
        }
        
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
        
        var errorDescription: String? {
            message
        }
        
    }
    
}
