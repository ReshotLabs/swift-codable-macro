//
//  Diagnostic.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/9.
//

import Foundation
import SwiftDiagnostics
import SwiftSyntax



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



struct InternalError: LocalizedError {

    let message: String
    let file: String 
    let line: Int 
    let column: Int 
    
    var errorDescription: String? { 
        "[swift-codable-macro] Internal Error: \(message) (\(file):\(line):\(column))"
    }

    init(message: String, file: String = #file, line: Int = #line, column: Int = #column) {
        self.message = message
        self.line = line
        self.column = column
        self.file = file
    }

}