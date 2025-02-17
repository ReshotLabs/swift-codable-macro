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



public struct CodingIgnoreMacro: PeerMacro {
    
    /// - Note: Just doing some validation, not doing any actual expansion
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws(DiagnosticsError) -> [SwiftSyntax.DeclSyntax] {
        
        guard let declaration = declaration.as(VariableDeclSyntax.self) else {
            throw .diagnostic(node: declaration, message: .decorator.general.attachTypeError)
        }
        
        guard let accessorBlock = declaration.bindings.first?.accessorBlock else {
            try checkCanBeIgnore(declaration, context: context)
            return []
        }
        
        guard let accessorDeclList = accessorBlock.accessors.as(AccessorDeclListSyntax.self) else {
            throw .diagnostic(node: declaration, message: .decorator.general.attachTypeError)
        }
        
        guard
            !accessorDeclList.lazy
                .map({ $0.accessorSpecifier.trimmed })
                .contains(where: { $0 == "set" || $0 == "get"})
        else {
            throw .diagnostic(node: declaration, message: .decorator.general.attachTypeError)
        }
        
        try checkCanBeIgnore(declaration, context: context)
        return []
        
    }
    
    
    static func checkCanBeIgnore(
        _ declaration: VariableDeclSyntax,
        context: some MacroExpansionContext
    ) throws(DiagnosticsError) {
        
        let hasInitializer = declaration.bindings.first?.initializer != nil
        let isOptional = declaration.bindings.first?.typeAnnotation?.type.is(OptionalTypeSyntax.self) == true
        
        guard hasInitializer || isOptional else {
            throw .diagnostic(node: declaration, message: .decorator.codingIgnore.cannotBeIgnored)
        }
        
    }
    
    
    
    enum Error {
        static let cannotBeIgnored: CodingDecoratorMacroDiagnosticMessage = .init(
            id: "can_not_be_ignored",
            message: "The field can only be ignored when it has a default value or is optional",
            severity: .error
        )
    }
    
}


extension CodingDecoratorMacroDiagnosticMessageGroup {
    static var codingIgnore: CodingIgnoreMacro.Error.Type { CodingIgnoreMacro.Error.self }
}
