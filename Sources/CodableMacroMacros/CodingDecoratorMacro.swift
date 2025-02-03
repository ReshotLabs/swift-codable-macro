//
//  CodingDecoratorMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/2.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


protocol CodingDecoratorMacro: PeerMacro {
    
    associatedtype CodingSpec
    typealias Error = CodingDecoratorMacroError
    
    static var macroArgumentsParsingRule: [ArgumentsParsingRule] { get }
    
    static func processProperty(
        _ propertyInfo: PropertyInfo,
        macroNodes: [SwiftSyntax.AttributeSyntax]
    ) throws(DiagnosticsError) -> CodingSpec
    
}


extension CodingDecoratorMacro {
    
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(VariableDeclSyntax.self) else {
            throw .diagnostic(node: declaration, message: Error.attachTypeError)
        }
        return []
    }
    
}



struct CodingDecoratorMacroError: LocalizedError, DiagnosticMessage {
    
    let id: String
    let rawMessage: String
    let severity: DiagnosticSeverity
    let isInternal: Bool
    
    var diagnosticID: MessageID {
        .init(domain: "com.serika.codable-macro.decorator-macro", id: id)
    }
    
    var message: String {
        "\(isInternal ? "Internal Error: " : "")\(rawMessage)"
    }
    
    var errorDescription: String? { message }
    
    
    init(id: String, message: String, severity: DiagnosticSeverity, isInternal: Bool = false) {
        self.id = id
        self.rawMessage = message
        self.severity = severity
        self.isInternal = isInternal
    }
    
    
    static let attachTypeError: Self = .init(
        id: "attach_type_error",
        message: "The Decorator macro for custom Coding can only be applied to stored properties",
        severity: .error
    )
    
    static func missingArgument(_ argumentName: String, isInternal: Bool = true) -> Self {
        .init(
            id: "missing_argument_\(argumentName)",
            message: "Missing required argument: \(argumentName)",
            severity: .error,
            isInternal: isInternal
        )
    }
    
    static func noArguments(isInternal: Bool = true) -> Self {
        .init(
            id: "no_arguments",
            message: "No arguments provided",
            severity: .error,
            isInternal: isInternal
        )
    }
    
    
    static func duplicateMacro(name: String) -> Self {
        .init(
            id: "multiple_\(name)",
            message: "A stored property should have at most one \(name) macro",
            severity: .error
        )
    }
    
}
