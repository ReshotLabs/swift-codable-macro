//
//  SingleValueCodableDelegateMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/3.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct SingleValueCodableDelegateMacro: CodingDecoratorMacro {
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("default", canIgnore: true)
    ]
    
    static func processProperty(
        _ propertyInfo: PropertyInfo,
        macroNodes: [AttributeSyntax],
        context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> ExprSyntax? {
        
        guard propertyInfo.type != .computed || macroNodes.isEmpty else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.attachTypeError)
        }
        
        guard macroNodes.count < 2 else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.duplicateMacro(name: "SingleValueCodableDelegate"))
        }
        
        guard let macroNode = macroNodes.first else {
            return nil 
        }

        let arguments = try macroNode.arguments?.grouped(with: macroArgumentsParsingRule)

        guard let defaultValue = arguments?[0].first?.expression else {
            return nil 
        }

        return defaultValue
        
    }
    
}
