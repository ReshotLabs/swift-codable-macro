//
//  MacroAssertUtils.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/20.
//


import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacroExpansion
import SwiftDiagnostics


func assertMacroExpansion(
    source originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macroSpecs: [String : MacroSpec] = testMacros,
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: macroSpecs,
        testModuleName: testModuleName,
        testFileName: testFileName,
        failureHandler: { spec in
            Issue.record(
                .init(rawValue: spec.message),
                sourceLocation: .init(
                    fileID: spec.location.fileID,
                    filePath: spec.location.filePath,
                    line: spec.location.line,
                    column: spec.location.column
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}



extension DiagnosticSpec {
    
    init(message: some DiagnosticMessage, line: Int, column: Int) {
        self.init(
            id: message.diagnosticID,
            message: message.message,
            line: line,
            column: column,
            severity: message.severity
        )
    }
    
}
