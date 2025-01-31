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
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let declaration = declaration.as(VariableDeclSyntax.self) else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        guard try PropertyInfo.extract(from: declaration).type != .computed else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        return []
    }
    
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .varArg(canIgnore: true), .labeled("default", canIgnore: true)
    ]
    
    
    static func processCodingField(
        _ property: PropertyInfo,
        macroNode: SwiftSyntax.AttributeSyntax
    ) throws(DiagnosticsError) -> (path: [String], defaultValue: ExprSyntax?) {
        
        guard property.type != .computed else {
            throw .diagnostic(node: property.name, message: Error.attachTypeError)
        }
        
        guard
            let macroRawArguments = macroNode.arguments?.as(LabeledExprListSyntax.self),
            macroRawArguments.isEmpty == false
        else {
            return ([property.name.trimmed.text], nil)
        }
        
        let (pathElements, defaultValue) = try extractPathAndDefault(from: macroRawArguments)
        
        return (pathElements ?? [property.name.trimmed.text], defaultValue)
        
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
