import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CodableMacroMacros)
import CodableMacroMacros

let testMacros: [String: Macro.Type] = [
    "Codable": CodableMacro.self,
    "CodingField": CodingFieldMacro.self,
    "CodingIgnore": CodingIgnoreMacro.self
]
#endif

final class CodableMacroTests: XCTestCase {
    
    func testMacro() throws {
        #if canImport(CodableMacroMacros)
        assertMacroExpansion(
            """
            @Codable
            struct TypeH: Equatable {
                @CodingIgnore
                @DecodeTransform(source: Int.self, with: advanceByOne(input:))
                @CodingField("a", "b", default: 2)
                var a: UInt = 1
                @CodingIgnore
                var b: Int = 1
            }
            """,
            expandedSource: """
            only god knows ...
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}
