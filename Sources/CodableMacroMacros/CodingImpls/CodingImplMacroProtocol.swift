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


protocol CodingMacroImplProtocol: ExtensionMacro, MemberMacro {
    
    static var supportedAttachedTypes: Set<CodingMacroImplBase.AttachedType> { get }
    static var macroArgumentsParsingRule: [ArgumentsParsingRule] { get }
    static var supportedDecorators: Set<DecoratorMacros> { get } 

    init(
        macroNode: AttributeSyntax,
        declGroup: some DeclGroupSyntax,
        context: MacroExpansionContext
    ) throws
    
    func makeConformingProtocols() throws -> [TypeSyntax]
    
    func makeDecls() throws -> [DeclSyntax]
    
}



extension CodingMacroImplProtocol {  
    
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let attachType = CodingMacroImplBase.AttachedType(from: declaration) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        guard supportedAttachedTypes.contains(attachType) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        return switch attachType {
            case .class, .actor: try Self.init(macroNode: node, declGroup: declaration, context: context).makeDecls()
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
        
        guard let attachType = CodingMacroImplBase.AttachedType(from: declaration) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        guard supportedAttachedTypes.contains(attachType) else {
            throw .diagnostic(node: declaration, message: .codingMacro.general.attachType(of: self))
        }
        
        let expander: Self
        do {
            expander = try Self.init(macroNode: node, declGroup: declaration, context: context)
        } catch {
            switch attachType {
                // for class / actor, errors related to initialization are handled when being expended as MemberMacro, 
                // so ignore them here
                case .class, .actor: return []
                default: throw error
            }
        }
        
        let conformingTypes = try expander.makeConformingProtocols()
        let extensionHeader = if conformingTypes.isEmpty {
            "extension \(type)"
        } else {
            "extension \(type): \(raw: conformingTypes.map(\.trimmedDescription).joined(separator: ", "))"
        } as SyntaxNodeString
        
        return switch attachType {
            case .actor, .class: [
                try .init(extensionHeader, membersBuilder: {})
            ]
            case .enum, .struct: [
                try .init(extensionHeader) {
                    try expander.makeDecls()
                }
            ]
        }
        
    }


    func gatherSupportedDecorators(in attributes: [AttributeSyntax]) -> [DecoratorMacros:[AttributeSyntax]] {
        return attributes.reduce(into: [DecoratorMacros:[AttributeSyntax]]()) { result, attribute in
            guard let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text else { return }
            guard let decoratorMacro = DecoratorMacros(rawValue: name) else { return }
            guard Self.supportedDecorators.contains(decoratorMacro) else { return }
            result[decoratorMacro, default: []].append(attribute)
        }
    }
    
}



class CodingMacroImplBase {

    let macroNode: MacroInfo
    let declGroup: DeclGroupSyntaxInfo
    let context: MacroExpansionContext

    required init(
        macroNode: MacroInfo, 
        declGroup: DeclGroupSyntaxInfo, 
        context: MacroExpansionContext
    ) throws {
        self.macroNode = macroNode
        self.declGroup = declGroup
        self.context = context
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


    struct Error: DiagnosticMessage {
    
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


    enum ErrorGroup {}

}



extension CodingMacroImplProtocol where Self: CodingMacroImplBase {
    
    init(
        macroNode: AttributeSyntax,
        declGroup: some DeclGroupSyntax,
        context: MacroExpansionContext
    ) throws {
        try self.init(
            macroNode: try MacroInfo.extract(from: macroNode, parsingRules: Self.macroArgumentsParsingRule), 
            declGroup: try DeclGroupSyntaxInfo.extract(from: declGroup), 
            context: context
        )
    }

}



extension DiagnosticMessage where Self == CodingMacroImplBase.Error {
    static var codingMacro: CodingMacroImplBase.ErrorGroup.Type { 
        CodingMacroImplBase.ErrorGroup.self 
    }
}



extension CodingMacroImplBase.ErrorGroup {

    enum General {
    
        static func attachType(of macro: (some CodingMacroImplProtocol).Type) -> CodingMacroImplBase.Error {
            .init(
                id: "attach_type",
                message: "\(macro.self) only supports \(macro.supportedAttachedTypes.map(\.description).joined(separator: ", "))"
            )
        }
        
        
        static var cannotInferType: CodingMacroImplBase.Error {
            .init(
                id: "cannot_infer_type",
                message: "Fail to infer explicit type of the property. Make sure to have an type annotation or an initializer"
            )
        }
        
        
        static var missingExplicitType: CodingMacroImplBase.Error {
            .init(
                id: "missing_explicit_type",
                message: "Explicit type annotation is required"
            )
        }


        static func conflictDecorators(_ decorator1: DecoratorMacros, _ decorator2: DecoratorMacros) -> CodingMacroImplBase.Error {
            .init(
                id: "conflict_decorators",
                message: "Decorator \(decorator1.rawValue) and \(decorator2.rawValue) cannot be used together"
            )
        }
        
    }

    static var general: General.Type { General.self }

}
