//
//  CodingIgnoreMacro.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/7.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



struct CodingIgnoreMacro: CodingDecoratorMacro {
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = []
    
    
    static func extractSetting(
        from macroNodes: [AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> Void {

    }
    
}
