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
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = []
    
    static func processProperty(
        _ propertyInfo: PropertyInfo,
        macroNodes: [AttributeSyntax]
    ) throws(DiagnosticsError) -> Void {
        
        guard propertyInfo.type != .computed || macroNodes.isEmpty else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.attachTypeError)
        }
        
        guard macroNodes.count < 2 else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.duplicateMacro(name: "SingleValueCodableDelegate"))
        }
        
        // no need to extract and information for now, may add something in the future
        
    }
    
}
