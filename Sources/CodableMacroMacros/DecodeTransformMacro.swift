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
    
    struct Spec: Equatable {
        var sourceTypeExpr: ExprSyntax
        var transformExpr: ExprSyntax
    }
    
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("source"),
        .labeled("target", canIgnore: true),
        .labeled("with")
    ]
    
    
    static func processProperty(
        _ propertyInfo: PropertyInfo,
        macroNodes: [SwiftSyntax.AttributeSyntax]
    ) throws(DiagnosticsError) -> Spec? {
        
        guard propertyInfo.type != .computed else {
            throw .diagnostic(node: propertyInfo.name, message: Error.attachTypeError)
        }
        
        guard macroNodes.count <= 1 else {
            throw .diagnostic(node: propertyInfo.name, message: Error.duplicateMacro(name: "DecodeTransformMacro"))
        }
        
        guard let macroNode = macroNodes.first else { return nil }
        
        guard let arguments = try macroNode.arguments?.grouped(with: macroArgumentsParsingRule) else {
            throw .diagnostic(node: macroNode, message: Error.noArguments())
        }
        
        guard let sourceTypeExpr = arguments[0].first?.expression.trimmed else {
            throw .diagnostic(node: macroNode, message: Error.missingArgument("soureType"))
        }
        guard let transformExpr = arguments[2].first?.expression.trimmed else {
            throw .diagnostic(node: macroNode, message: Error.missingArgument("transform"))
        }
        
        return .init(sourceTypeExpr: sourceTypeExpr, transformExpr: transformExpr)
        
    }
    
}
