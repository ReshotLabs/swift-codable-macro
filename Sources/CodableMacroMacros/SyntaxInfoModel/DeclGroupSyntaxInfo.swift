//
//  DeclGroupSyntaxInfo.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/10.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct DeclGroupSyntaxInfo: Sendable {
    
    let name: TokenSyntax
    let type: DeclType
    let inheritance: [TypeSyntax]
    let properties: [PropertyInfo]
    let modifiers: DeclModifierListSyntax
    let initializers: [InitializerDeclSyntax]
    let enumCases: [EnumCaseInfo]

    var hasInitializer: Bool {
        initializers.isEmpty == false
    }
    
    
    static func extract(from syntax: some DeclGroupSyntax) throws(DiagnosticsError) -> Self {
        let (name, type) = if let classDecl = syntax.as(ClassDeclSyntax.self) {
            (classDecl.name, .class)
        } else if let structDecl = syntax.as(StructDeclSyntax.self) {
            (structDecl.name, .struct)
        } else if let enumDecl = syntax.as(EnumDeclSyntax.self) {
            (enumDecl.name, .enum)
        } else if let actorDecl = syntax.as(ActorDeclSyntax.self) {
            (actorDecl.name, .actor)
        } else {
            throw .diagnostic(
                node: syntax,
                message: .syntaxInfo.declGroup.unSupportedDeclType(syntax.introducer)
            )
        } as (TokenSyntax, DeclType)
        return .init(
            name: name,
            type: type,
            inheritance: syntax.inheritanceClause?.inheritedTypes.map(\.type) ?? [],
            properties: try syntax.memberBlock.members
                .compactMap { $0.decl.as(VariableDeclSyntax.self) }
                .map(PropertyInfo.extract(from:)),
            modifiers: syntax.modifiers,
            initializers: syntax.memberBlock.members
                .compactMap { $0.decl.as(InitializerDeclSyntax.self) },
            enumCases: try syntax.memberBlock.members
                .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
                .map(EnumCaseInfo.extract(from:))
                .flatMap(\.self)
        )
    }
    
    
    enum Error {
        static func unSupportedDeclType(_ introducer: TokenSyntax) -> SyntaxInfoDiagnosticMessage {
            .init(id: "un_supported_decl_type", message: "Unsupported decl type: \(introducer)")
        }
    }
    
}



extension DeclGroupSyntaxInfo: Equatable, Hashable {}



extension SyntaxInfoDiagnosticMessageGroup {
    static var declGroup: DeclGroupSyntaxInfo.Error.Type {
        DeclGroupSyntaxInfo.Error.self
    }
}



extension DeclGroupSyntaxInfo {
    
    enum DeclType: CustomStringConvertible, Equatable {
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
    
}
