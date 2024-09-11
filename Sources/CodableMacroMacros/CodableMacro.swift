//
//  CodableMacro.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/7.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



public struct CodableMacro: ExtensionMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
        guard declaration.is(ClassDeclSyntax.self) || declaration.is(StructDeclSyntax.self) else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
        let codingFieldInfoList = try extractCodingFieldInfoList(
            from: declaration.memberBlock.members,
            in: context
        )
        
        guard
            !codingFieldInfoList.isEmpty,
            codingFieldInfoList.contains(where: {
                $0.path.count > 1
                || $0.field.defaultValue != nil
                || $0.path.first != $0.field.name.trimmed.text
            })
        else {
            return [try .init("extension \(type.trimmed): Codable", membersBuilder: {})]
        }
        
        let structure = try CodingStructure.parse(codingFieldInfoList)
        
        let (enumDecls, operations) = try buildOperations(
            from: structure,
            context: context,
            macroNode: node
        )
        
        return [
            try .init("extension \(type.trimmed): Codable") {
                generateEnumDeclarations(from: enumDecls)
                try generateDecodeInitializer(from: operations, context: context)
                try generateEncodeMethod(from: operations)
            }
        ]
        
    }

    
    
    enum Error: String, DiagnosticMessage {
        
        case attachTypeError = "attach_type"
        case noIdentifierFound = "no_identifier"
        case multipleCodingField = "multiple_coding_field"
        case unexpectedEmptyEnumStack = "unexpected_empty_enum_stack"
        
        
        var message: String {
            switch self {
                case .attachTypeError: "The Codable macro can only be applied to class or struct declaration"
                case .noIdentifierFound: "The Codable macro can only be applied to class or struct declaration"
                case .multipleCodingField: "A stored property should have at most one CodingField macro"
                case .unexpectedEmptyEnumStack: "Internal Error: unexpected empty enum stack"
            }
        }
        
        var diagnosticID: SwiftDiagnostics.MessageID {
            .init(domain: "com.serika.codable_macro.codable", id: self.rawValue)
        }
        
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
        
    }
    
}
