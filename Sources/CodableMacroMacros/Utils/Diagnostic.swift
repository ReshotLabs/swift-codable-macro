//
//  Diagnostic.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/9.
//

import Foundation
import SwiftDiagnostics
import SwiftSyntax


struct StringDiagnosticsMessage: DiagnosticMessage {
    
    let message: String
    private(set) var severity: DiagnosticSeverity = .error
    
    let diagnosticID: MessageID = .init(domain: "com.serika.coding_macro", id: UUID().uuidString)
    
}


extension DiagnosticMessage where Self == StringDiagnosticsMessage {
    static func string(_ message: String, severity: DiagnosticSeverity = .error) -> Self {
        .init(message: message, severity: severity)
    }
}



struct StringNoteMessage: NoteMessage {
    let message: String
    let noteID: MessageID = .init(domain: "com.serika.coding_macro", id: UUID().uuidString)
}


extension NoteMessage where Self == StringNoteMessage {
    static func string(_ message: String) -> Self {
        .init(message: message)
    }
}



extension Error where Self == DiagnosticsError {
    
    static func diagnostic(
        node: some SyntaxProtocol,
        position: AbsolutePosition? = nil,
        message: DiagnosticMessage,
        highlights: [Syntax]? = nil,
        notes: [Note] = [],
        fixIts: [FixIt] = []
    ) -> Self {
        .init(
            diagnostics: [
                .init(
                    node: node,
                    position: position,
                    message: message,
                    highlights: highlights,
                    notes: notes,
                    fixIts: fixIts
                )
            ]
        )
    }
    
    
    static func diagnostic(
        node: some SyntaxProtocol,
        position: AbsolutePosition? = nil,
        message: DiagnosticMessage,
        highlights: [Syntax]? = nil,
        notes: [Note] = [],
        fixIt: FixIt
    ) -> Self {
        .init(
            diagnostics: [
                .init(
                    node: node,
                    position: position,
                    message: message,
                    highlights: highlights,
                    notes: notes,
                    fixIt: fixIt
                )
            ]
        )
    }
    
    
    static func diagnostics(_ dianostics: [Diagnostic]) -> Self {
        .init(diagnostics: dianostics)
    }
    
}
