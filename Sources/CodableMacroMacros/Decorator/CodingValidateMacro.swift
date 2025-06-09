//
//  CodingValidateMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/2.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


struct CodingValidateMacro: CodingDecoratorMacro {
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("source"),
        .labeled("with"),
    ]
    
    
    static func extractSetting(
        from macroNodes: [AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> [ExprSyntax] {
        
        return try macroNodes.map { (attribute) throws(DiagnosticsError) in
            
            guard let arguments = try attribute.arguments?.grouped(with: macroArgumentsParsingRule) else {
                throw .diagnostic(node: attribute, message: .decorator.general.noArguments())
            }
            
            guard let validExpr = arguments[1].first?.expression.trimmed else {
                throw .diagnostic(node: attribute, message: .decorator.general.missingArgument("validate"))
            }
            
            return validExpr
            
        }
        
    }
    
}
