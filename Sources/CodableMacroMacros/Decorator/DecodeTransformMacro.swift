//
//  DecodeTransformMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/1.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation



struct DecodeTransformMacro: CodingDecoratorMacro {
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("source"),
        .labeled("target", canIgnore: true),
        .labeled("with")
    ]
    
    
    static func extractSetting(
        from macroNodes: [SwiftSyntax.AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> Spec? {
        
        guard macroNodes.count < 2 else {
            throw .diagnostics(macroNodes.map { .init(node: $0, message: .decorator.general.duplicateMacro(name: "DecodeTransform")) })
        }
        
        guard let macroNode = macroNodes.first else { return nil }
        
        guard let arguments = try macroNode.arguments?.grouped(with: macroArgumentsParsingRule) else {
            throw .diagnostic(node: macroNode, message: .decorator.general.noArguments())
        }
        
        guard let sourceTypeExpr = arguments[0].first?.expression.trimmed else {
            throw .diagnostic(node: macroNode, message: .decorator.general.missingArgument("soureType"))
        }
        guard let transformExpr = arguments[2].first?.expression.trimmed else {
            throw .diagnostic(node: macroNode, message: .decorator.general.missingArgument("transform"))
        }
        
        return .init(
            decodeSourceType: sourceTypeExpr,
            transforms: transformExpr
        )
        
    }
    
    
    struct Spec {
        var decodeSourceType: ExprSyntax
        var transforms: ExprSyntax
    }
    
}
