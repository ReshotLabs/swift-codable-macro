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
        
        return if declaration.is(ClassDeclSyntax.self) {
            [try .init("extension \(type.trimmed): Codable", membersBuilder: {})]
        } else if declaration.is(StructDeclSyntax.self) {
            [
                try .init("extension \(type.trimmed): Codable") {
                    try makeDecls(node: node, declaration: declaration, context: context)
                }
            ]
        } else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
    }

    
    
    enum Error: String, DiagnosticMessage {
        
        case attachTypeError = "attach_type"
        case noIdentifierFound = "no_identifier"
        case multipleCodingField = "multiple_coding_field"
        case unexpectedEmptyContainerStack = "unexpected_empty_container_stack"
        case unexpectedNilDefaultValue = "unexpected_nil_default_value"
        
        
        var message: String {
            switch self {
                case .attachTypeError: "The Codable macro can only be applied to class or struct declaration"
                case .noIdentifierFound: "The Codable macro can only be applied to class or struct declaration"
                case .multipleCodingField: "A stored property should have at most one CodingField macro"
                case .unexpectedEmptyContainerStack: "Internal Error: unexpected empty container stack"
                case .unexpectedNilDefaultValue: "Internal Error: unexpected nil default value, which should have been filtered out"
            }
        }
        
        var diagnosticID: SwiftDiagnostics.MessageID {
            .init(domain: "com.serika.codable_macro.codable", id: self.rawValue)
        }
        
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
        
    }
    
}



extension CodableMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        if declaration.is(ClassDeclSyntax.self) {
            return try makeDecls(node: node, declaration: declaration, context: context)
        } else if declaration.is(StructDeclSyntax.self) {
            return []
        } else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        
    }
    
}



extension CodableMacro {
    
    static func makeDecls(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let isClass = declaration.is(ClassDeclSyntax.self)
        let isNonFinalClass = isClass && declaration.as(ClassDeclSyntax.self)?.modifiers
            .contains(where: { $0.name.tokenKind == .keyword(.final) }) == false
        
        let (codingFieldInfoList, canAutoCodable) = try extractCodingFieldInfoList(from: declaration.memberBlock.members)
        
        /// Whether an empty initializer should be created, only for class
        var autoInit: Bool {
            isClass
            && !codingFieldInfoList.contains(where: { $0.propertyInfo.isRequired })   // all stored properties are initialized
            && !declaration.memberBlock.members.contains(where: { $0.decl.is(InitializerDeclSyntax.self) })     // has no initializer
        }
        
        // use the auto implementation provided by Swift Compiler if:
        // * no actual customization is found
        // * target is non-final class (where auto implementation will fail on extension)
        guard isNonFinalClass || !canAutoCodable else { return [] }
        
        guard !codingFieldInfoList.isEmpty else {
            // If the info list is still empty here, the type is a class that is not final
            // with no stored property, should not proceed further
            // Create an empty decode initializer since the auto-implementation will fail in this case
            return if autoInit {
                [
                    "init() {}",
                    "public required init(from decoder: Decoder) throws {}"
                ]
            } else {
                ["public required init(from decoder: Decoder) throws {}"]
            }
        }
        
        // Analyse the stored properties and convert into a tree structure
        let structure = try CodingStructure.parse(codingFieldInfoList)
   
        // Convert the tree structure into actual "steps" for encoding and decoding
        let (operations, enumDecls) = try buildCodingSteps(
            from: structure,
            context: context,
            macroNode: node
        )
        
        var decls = [DeclSyntax]()
        
        decls += generateEnumDeclarations(from: enumDecls)
        decls += try generateDecodeInitializer(from: operations, isClass: isClass, context: context)
        decls.append(try generateEncodeMethod(from: operations))
        
        if autoInit {
            decls.append("init() {}")
        }
        
        return decls
        
    }
    
}
