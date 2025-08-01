//
//  EncodeTransformMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/1.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct EncodeTransformMacro: CodingDecoratorMacro {
    
    struct Spec: Equatable {
        let sourceTypeExpr: ExprSyntax
        let transformExpr: ExprSyntax
    }
    
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("source"),
        .labeled("target", canIgnore: true),
        .labeled("with")
    ]
    
    
    static func extractSetting(
        from macroNodes: [SwiftSyntax.AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> ExprSyntax? {
        
        guard macroNodes.count < 2 else {
            throw .diagnostics(macroNodes.map { .init(node: $0, message: .decorator.general.duplicateMacro(name: "EncodeTransform")) })
        }
        
        guard let macroNode = macroNodes.first else { return nil }
        
        guard let arguments = try macroNode.arguments?.grouped(with: macroArgumentsParsingRule) else {
            throw .diagnostic(node: macroNode, message: .decorator.general.noArguments())
        }
        
        guard let transformExpr = arguments[2].first?.expression.trimmed else {
            throw .diagnostic(node: macroNode, message: .decorator.general.missingArgument("transform"))
        }
        
        return transformExpr
        
    }
    
}
