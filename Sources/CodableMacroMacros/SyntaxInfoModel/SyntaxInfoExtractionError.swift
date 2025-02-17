//
//  Error.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/16.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



struct SyntaxInfoDiagnosticMessage: DiagnosticMessage {
    
    let id: String
    let message: String
    let severity: DiagnosticSeverity
    
    var domain: String { "com.serika.codable-macro.syntax-info" }
    var diagnosticID: MessageID {
        .init(domain: domain, id: id)
    }
    
    init(id: String, message: String, severity: DiagnosticSeverity = .error) {
        self.id = id
        self.message = message
        self.severity = severity
    }
    
}



enum SyntaxInfoDiagnosticMessageGroup {}



extension DiagnosticMessage where Self == SyntaxInfoDiagnosticMessage {
    static var syntaxInfo: SyntaxInfoDiagnosticMessageGroup.Type {
        SyntaxInfoDiagnosticMessageGroup.self
    }
}
