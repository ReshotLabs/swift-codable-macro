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



protocol CodingDecoratorMacro: PeerMacro {
    
    associatedtype CodingSetting
    
    static var macroArgumentsParsingRule: [ArgumentsParsingRule] { get }
    
    static func extractSetting(
        from macroNodes: [SwiftSyntax.AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> CodingSetting
    
}



extension CodingDecoratorMacro {
    
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
    
}



struct CodingDecoratorMacroDiagnosticMessage: DiagnosticMessage {
    
    let id: String
    let rawMessage: String
    let severity: DiagnosticSeverity
    let isInternal: Bool
    
    var diagnosticID: MessageID {
        .init(domain: "com.serika.codable-macro.decorator", id: id)
    }
    
    var message: String {
        "\(isInternal ? "Internal Error: " : "")\(rawMessage)"
    }
    
    
    init(id: String, message: String, severity: DiagnosticSeverity = .error, isInternal: Bool = false) {
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



enum CodingDecoratorMacroDiagnosticMessageGroup {}



extension DiagnosticMessage where Self == CodingDecoratorMacroDiagnosticMessage {
    static var decorator: CodingDecoratorMacroDiagnosticMessageGroup.Type { CodingDecoratorMacroDiagnosticMessageGroup.self }
}



enum GeneralCodingDecoratorMacroDiagnosticMessage {
    
    static let attachTypeError: CodingDecoratorMacroDiagnosticMessage = .init(
        id: "attach_type_error",
        message: "The Decorator macro for custom Coding can only be applied to stored properties",
        severity: .error
    )
    
    static func missingArgument(_ argumentName: String, isInternal: Bool = true) -> CodingDecoratorMacroDiagnosticMessage {
        .init(
            id: "missing_argument_\(argumentName)",
            message: "Missing required argument: \(argumentName)",
            severity: .error,
            isInternal: isInternal
        )
    }
    
    static func noArguments(isInternal: Bool = false) -> CodingDecoratorMacroDiagnosticMessage {
        .init(
            id: "no_arguments",
            message: "No arguments provided",
            severity: .error,
            isInternal: isInternal
        )
    }
    
    
    static func duplicateMacro(name: String) -> CodingDecoratorMacroDiagnosticMessage {
        .init(
            id: "multiple_\(name)",
            message: "A stored property should have at most one \(name) macro",
            severity: .error
        )
    }
    
    
    static func conflictDecorators(_ decorators: [String]) -> CodingDecoratorMacroDiagnosticMessage {
        .init(
            id: "conflicting_decorators",
            message: "\(decorators.joined(separator: ", ")) cannot be used together",
            severity: .error
        )
    }

    static func notLiteral() -> CodingDecoratorMacroDiagnosticMessage {
        .init(
            id: "not_literal",
            message: "Expect a literal value",
            severity: .error
        )
    }

    static func notStaticStringLiteral() -> CodingDecoratorMacroDiagnosticMessage {
        .init(
            id: "not_static_string_literal",
            message: "Expect a static string literal without interpolation",
            severity: .error
        )
    }

    static func notRawTypeExpr() -> CodingDecoratorMacroDiagnosticMessage {
        .init(id: "not_raw_type_expr", message: "Expect <Type>.self format", severity: .error)
    }
    
}



extension CodingDecoratorMacroDiagnosticMessageGroup {
    static var general: GeneralCodingDecoratorMacroDiagnosticMessage.Type {
        GeneralCodingDecoratorMacroDiagnosticMessage.self
    }
}
