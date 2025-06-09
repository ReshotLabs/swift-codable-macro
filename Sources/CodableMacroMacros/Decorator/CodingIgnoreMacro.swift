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
    
    
    enum Error {
        static let cannotBeIgnored: CodingDecoratorMacroDiagnosticMessage = .init(
            id: "can_not_be_ignored",
            message: "The property can only be ignored when it has a default value or is optional",
            severity: .error
        )
    }
    
}


extension CodingDecoratorMacroDiagnosticMessageGroup {
    static var codingIgnore: CodingIgnoreMacro.Error.Type { CodingIgnoreMacro.Error.self }
}
