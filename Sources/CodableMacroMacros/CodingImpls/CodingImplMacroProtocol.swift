//
//  CodingImplMacroProtocol.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/3.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


protocol CodingImplMacroProtocol: ExtensionMacro, MemberMacro {
    
    static var supportedAttachedTypes: Set<AttachedType> { get }
    
    static func makeExtensionHeader(
        node: AttributeSyntax,
        type: some TypeSyntaxProtocol,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> SyntaxNodeString
    
    static func makeDecls(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax]
    
}



extension CodingImplMacroProtocol {
    
    static func shouldAutoInit<Seq: Sequence>(
        declaration: some DeclGroupSyntax,
        properties: Seq
    ) -> Bool where Seq.Element == PropertyInfo {
        declaration.is(ClassDeclSyntax.self)
        && !properties.contains(where: { $0.isRequired })                                                   // all stored properties are initialized
        && !declaration.memberBlock.members.contains(where: { $0.decl.is(InitializerDeclSyntax.self) })     // has no initializer
    }
    
    
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let attachType = AttachedType(from: declaration) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        guard supportedAttachedTypes.contains(attachType) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        return switch attachType {
            case .class, .actor: try makeDecls(node: node, declaration: declaration, context: context)
            case .struct, .enum: []
        }
    }
    
    
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let attachType = AttachedType(from: declaration) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        guard supportedAttachedTypes.contains(attachType) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        let extensionHeader = try makeExtensionHeader(node: node, type: type, declaration: declaration, context: context)
        return switch attachType {
            case .actor, .class: [
                try .init(extensionHeader, membersBuilder: {})
            ]
            case .enum, .struct: [
                try .init(extensionHeader) {
                    try makeDecls(node: node, declaration: declaration, context: context)
                }
            ]
        }
    }
    
}



struct CodingMacroDiagnosticMessage: DiagnosticMessage {
    
    let id: String
    let message: String
    let severity: DiagnosticSeverity
    
    var domain: String { "com.serika.codable-macro.coding-macro" }
    
    init(id: String, message: String, severity: DiagnosticSeverity = .error) {
        self.id = id
        self.message = message
        self.severity = severity
    }
    
    var diagnosticID: MessageID { .init(domain: domain, id: id) }
    
}



enum CodingMacroDiagnosticMessageGroup {}



extension DiagnosticMessage where Self == CodingMacroDiagnosticMessage {
    static var codingMacro: CodingMacroDiagnosticMessageGroup.Type { CodingMacroDiagnosticMessageGroup.self }
}



enum GeneralCodingMacroDiagnosticMessage {
    
    static func attachType(of macro: (some CodingImplMacroProtocol).Type) -> CodingMacroDiagnosticMessage {
        .init(
            id: "attach_type",
            message: "\(macro.self) only supports \(macro.supportedAttachedTypes.map(\.description).joined(separator: ", "))"
        )
    }
    
    
    static var cannotInferType: CodingMacroDiagnosticMessage {
        .init(
            id: "cannot_infer_type",
            message: "Fail to infer explicit type of the property. Make sure to have an type annotation or an initializer"
        )
    }
    
    
    static var missingExplicitType: CodingMacroDiagnosticMessage {
        .init(
            id: "missing_explicit_type",
            message: "Explicit type annotation is required for the property"
        )
    }
    
}


extension CodingMacroDiagnosticMessageGroup {
    static var general: GeneralCodingMacroDiagnosticMessage.Type {
        GeneralCodingMacroDiagnosticMessage.self
    }
}



enum AttachedType: CustomStringConvertible {
    case `class`, `struct`, `enum`, actor
    init?(from declSyntax: DeclGroupSyntax) {
        switch true {
            case declSyntax.is(ClassDeclSyntax.self): self = .class
            case declSyntax.is(StructDeclSyntax.self): self = .struct
            case declSyntax.is(EnumDeclSyntax.self): self = .enum
            case declSyntax.is(ActorDeclSyntax.self): self = .actor
            default: return nil
        }
    }
    var description: String {
        switch self {
            case .class: "Class"
            case .struct: "Struct"
            case .enum: "Enum"
            case .actor: "Actor"
        }
    }
}
