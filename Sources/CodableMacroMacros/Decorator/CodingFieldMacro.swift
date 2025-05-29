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



struct CodingFieldMacro: CodingDecoratorMacro {
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .varArg(canIgnore: true), 
        .labeled("default", canIgnore: true), 
        .labeledVarArg("onMissing", canIgnore: true), 
        .labeledVarArg("onMismatch", canIgnore: true)
    ]
    
    
    static func processProperty(
        _ property: PropertyInfo,
        macroNodes: [SwiftSyntax.AttributeSyntax],
        context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> (path: [String], defaultValueOnMissing: ExprSyntax?, defaultValueOnMismatch: ExprSyntax?)? {
        
        guard property.type != .computed else {
            if macroNodes.isEmpty {
                return nil
            } else {
                throw .diagnostic(node: property.name, message: .decorator.general.attachTypeError)
            }
        }
        
        guard macroNodes.count < 2 else {
            throw .diagnostic(node: property.name, message: .decorator.general.duplicateMacro(name: "CodingField"))
        }
        
        guard let macroNode = macroNodes.first else {
            return ([property.name.trimmed.text], nil, nil)
        }
        
        guard
            let macroRawArguments = macroNode.arguments?.as(LabeledExprListSyntax.self),
            macroRawArguments.isEmpty == false
        else {
            return ([property.name.trimmed.text], nil, nil)
        }
        
        let (pathElements, defaultValueOnMissing, defaultValueOnMismatch) = try extractPathAndDefault(from: macroRawArguments)
        
        if let defaultValue = defaultValueOnMissing ?? defaultValueOnMismatch, 
           property.initializer != nil, property.type == .constant 
        {
            throw .diagnostic(node: defaultValue, message: .decorator.codingField.defaultValueOnConstantwithInitializer)
        }
        
        return (pathElements ?? [property.name.trimmed.text], defaultValueOnMissing, defaultValueOnMismatch)
        
    }
    
    
    static func extractPathAndDefault(
        from macroArguments: LabeledExprListSyntax
    ) throws(DiagnosticsError) -> (pathElements: [String]?, defaultValueOnMissing: ExprSyntax?, defaultValueOnMismatch: ExprSyntax?) {
        
        let arguments = try macroArguments.grouped(with: macroArgumentsParsingRule)
        
        let pathElements = if arguments[0].isEmpty {
            nil as [String]?
        } else {
            arguments[0].compactMap {
                $0.expression.as(StringLiteralExprSyntax.self)?.segments.description
            }
        }
        let defaultValue = arguments[1].first?.expression
        let onMissing = arguments[2].first?.expression ?? defaultValue
        let onMismatch = arguments[3].first?.expression ?? defaultValue
        
        guard (pathElements?.count ?? 0) == arguments[0].count else {
            throw .diagnostic(node: macroArguments, message: .decorator.codingField.notStringLiteral)
        }
        
        return (pathElements, onMissing, onMismatch)
        
    }
    
}


extension CodingFieldMacro {
    
    enum CodingFieldMacroError {
        static let notStringLiteral: CodingDecoratorMacroDiagnosticMessage = .init(
            id: "no_string_literal",
            message: "The path can be specified using string literal",
            severity: .error
        )
        static let defaultValueOnConstantwithInitializer: CodingDecoratorMacroDiagnosticMessage = .init(
            id: "default_value_on_constant_with_initializer",
            message: "Default value cannot be specified on a constant with an initializer",
            severity: .error
        )
    }
    
}



extension CodingDecoratorMacroDiagnosticMessageGroup {
    
    static var codingField: CodingFieldMacro.CodingFieldMacroError.Type {
        CodingFieldMacro.CodingFieldMacroError.self
    }
    
}
