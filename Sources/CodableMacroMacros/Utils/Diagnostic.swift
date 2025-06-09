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



struct InternalDiagnosticError: DiagnosticMessage {

    private let _message: String
    let diagnosticID: MessageID = .init(domain: "com.serika.coding_macro.internal", id: UUID().uuidString)

    var severity: DiagnosticSeverity { .error }
    var message: String {
        "[Internal Error]: \(_message)"
    }

    init(message: String) {
        self._message = message
    }

}



extension DiagnosticMessage where Self == InternalDiagnosticError {

    static var `internal`: Self.Type {
        Self.self
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



typealias DiagnosticResult<T> = Result<T, DiagnosticsError>
typealias DiagnosticResultSequence<T> = [DiagnosticResult<T>]



func mapDiagnosticResults<each R, T>(_ results: repeat DiagnosticResult<each R>, transform: ((repeat each R)) -> T) -> DiagnosticResult<T> {
    do {
        return try .success(transform((repeat (each results).get())))
    } catch {
        var diagnostics = [Diagnostic]()
        for result in repeat each results {
            if case .failure(let diagnosticsError) = result {
                diagnostics.append(contentsOf: diagnosticsError.diagnostics)   
            }
        }
        return .failure(.init(diagnostics: diagnostics))
    }
}



extension DiagnosticResultSequence {

    func collectDiagnostics<T>() -> [Diagnostic] where Element == DiagnosticResult<T> {
        var diagnostics: [Diagnostic] = []
        for result in self {
            if case .failure(let error) = result {
                diagnostics.append(contentsOf: error.diagnostics)
            }
        }
        return diagnostics
    }


    func collectResults<T>() -> [T] where Element == DiagnosticResult<T>  {
        var results: [T] = []
        for result in self {
            if case .success(let value) = result {
                results.append(value)
            }
        }
        return results
    }


    func mapResult<ResultIn, ResultOut>(
        _ operation: (ResultIn) -> DiagnosticResult<ResultOut>
    ) -> DiagnosticResultSequence<ResultOut> where Element == DiagnosticResult<ResultIn> {
        return self.map { result in
            switch result {
            case .success(let value):
                return operation(value)
            case .failure(let error):
                return .failure(error)
            }
        }
    }


    func apply<T>(_ operation: (Self) -> Self) -> Self where Element == DiagnosticResult<T> {
        return operation(self)
    }


    func throwDiagnosticsAsError<T>() throws(DiagnosticsError) -> [T] where Element == DiagnosticResult<T> {
        var results: [T] = []
        var errors: [Diagnostic] = []
        for result in self {
            switch result {
            case .success(let value):
                results.append(value)
            case .failure(let error):
                errors.append(contentsOf: error.diagnostics)
            }
        }
        guard errors.isEmpty else {
            throw .diagnostics(errors)
        }
        return results
    }
    
}