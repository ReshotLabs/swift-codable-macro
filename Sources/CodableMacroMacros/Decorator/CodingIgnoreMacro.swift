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
    
    
    static func processProperty(
        _ propertyInfo: PropertyInfo,
        macroNodes: [AttributeSyntax]
    ) throws(DiagnosticsError) -> Void {
        
        guard !macroNodes.isEmpty else { return }
        
        guard propertyInfo.type != .computed else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.attachTypeError)
        }

        if propertyInfo.initializer == nil && !propertyInfo.hasOptionalTypeDecl {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.codingIgnore.cannotBeIgnored)
        }

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
