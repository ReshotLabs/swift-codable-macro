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
    
    
    static func extractSetting(
        from macroNodes: [SwiftSyntax.AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> (path: [String]?, defaultValueOnMissing: ExprSyntax?, defaultValueOnMismatch: ExprSyntax?)? {
        
        guard macroNodes.count < 2 else {
            throw .diagnostics(macroNodes.map { .init(node: $0, message: .decorator.general.duplicateMacro(name: "CodingField")) })
        }

        guard let macroNode = macroNodes.first else { return nil }
        
        guard
            let macroRawArguments = macroNode.arguments?.as(LabeledExprListSyntax.self),
            macroRawArguments.isEmpty == false
        else {
            return (nil, nil, nil)
        }
        
        let (pathElements, defaultValueOnMissing, defaultValueOnMismatch) = try extractPathAndDefault(from: macroRawArguments)
        
        return (pathElements, defaultValueOnMissing, defaultValueOnMismatch)
        
    }
    
    
    static func extractPathAndDefault(
        from macroArguments: LabeledExprListSyntax
    ) throws(DiagnosticsError) -> (pathElements: [String]?, defaultValueOnMissing: ExprSyntax?, defaultValueOnMismatch: ExprSyntax?) {
        
        let arguments = try macroArguments.grouped(with: macroArgumentsParsingRule)
        
        let pathElements = if arguments[0].isEmpty {
            nil
        } else {
            arguments[0].map { arg in
                (arg.expression.as(StringLiteralExprSyntax.self))
                    .map { .success($0.segments.description) }
                    .orElse {
                        .failure(.diagnostic(node: arg.expression, message: .decorator.codingField.pathElementNotStringLiteral))
                    }
            } 
        } as DiagnosticResultSequence<String>?
        let defaultValue = arguments[1].first?.expression
        let onMissing = arguments[2].first?.expression ?? defaultValue
        let onMismatch = arguments[3].first?.expression ?? defaultValue
        
        return (try pathElements?.getResults(), onMissing, onMismatch)
        
    }
    
}


extension CodingFieldMacro {
    
    enum CodingFieldMacroError {
        static let pathElementNotStringLiteral: CodingDecoratorMacroDiagnosticMessage = .init(
            id: "path_element_not_string_literal",
            message: "The path can only be specified using string literal"
        )
    }
    
}



extension CodingDecoratorMacroDiagnosticMessageGroup {
    
    static var codingField: CodingFieldMacro.CodingFieldMacroError.Type {
        CodingFieldMacro.CodingFieldMacroError.self
    }
    
}
