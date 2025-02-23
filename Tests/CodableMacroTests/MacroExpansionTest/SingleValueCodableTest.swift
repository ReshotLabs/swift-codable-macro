//
//  SingleValueCodableTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/22.
//

import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import Foundation

@testable import CodableMacro

#if canImport(CodableMacroMacros)
@testable import CodableMacroMacros
#endif


@Suite("Test SingleValueCodable macro", .tags(.expansion.singleValueCoding))
struct SingleValueCodableTest {
    
    @SingleValueCodable
    struct Test1 {
        var a: Int
        func singleValueEncode() throws -> String {
            a.description
        }
        init(from codingValue: String) throws {
            self.a = Int(codingValue)!
        }
    }
    
    @Test("custom coding function", .tags(.expansion.singleValueCoding))
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                var a: Int
                func singleValueEncode() throws -> String {
                    a.description
                }
                init(from codingValue: String) throws {
                    self.a = Int(codingValue)!
                }
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int
                func singleValueEncode() throws -> String {
                    a.description
                }
                init(from codingValue: String) throws {
                    self.a = Int(codingValue)!
                }
            }
            
            extension Test: SingleValueCodableProtocol {
            }
            """
        )
    }
    
    
    @SingleValueCodable
    struct Test2 {
        @SingleValueCodableDelegate
        var a: Int
    }
    
    @Test("var | delegate", .tags(.expansion.singleValueCoding, .expansion.mutableProperty))
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                @SingleValueCodableDelegate
                var a: Int
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int
            }
            
            extension Test: SingleValueCodableProtocol {
                public func singleValueEncode() throws -> Int {
                    return self.a
                }
                public init(from codingValue: Int) throws {
                    self.a = codingValue
                }
            }
            """
        )
    }
    
    
    @SingleValueCodable
    struct Test3 {
        @SingleValueCodableDelegate
        var a: Int?
    }
    
    @Test(
        "var | delegate | optional",
        .tags(.expansion.singleValueCoding, .expansion.mutableProperty, .expansion.optionalProperty)
    )
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                @SingleValueCodableDelegate
                var a: Int?
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int?
            }
            
            extension Test: SingleValueCodableProtocol {
                public func singleValueEncode() throws -> Int? {
                    return self.a
                }
                public init(from codingValue: Int?) throws {
                    self.a = codingValue
                }
                public static var singleValueCodingDefaultValue: Int?? {
                    nil as Int?
                }
            }
            """
        )
    }
    
    
    @SingleValueCodable
    struct Test4 {
        @SingleValueCodableDelegate
        var a: Int = 1
    }
    
    @Test(
        "var | delegate | initializer",
        .tags(.expansion.singleValueCoding, .expansion.mutableProperty, .expansion.initializerProperty)
    )
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                @SingleValueCodableDelegate
                var a: Int = 1
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int = 1
            }
            
            extension Test: SingleValueCodableProtocol {
                public func singleValueEncode() throws -> Int {
                    return self.a
                }
                public init(from codingValue: Int) throws {
                    self.a = codingValue
                }
                public static var singleValueCodingDefaultValue: Int? {
                    1
                }
            }
            """
        )
    }
    
    
    @SingleValueCodable
    struct Test5 {
        @SingleValueCodableDelegate
        let a: Int = 1
    }
    
    @Test(
        "let | delegate | initializer",
        .tags(.expansion.singleValueCoding, .expansion.constantProperty, .expansion.initializerProperty)
    )
    func test5() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                @SingleValueCodableDelegate
                let a: Int = 1
            }
            """,
            expandedSource: """
            struct Test {
                let a: Int = 1
            }
            
            extension Test: SingleValueCodableProtocol {
                public func singleValueEncode() throws -> Int {
                    return self.a
                }
                public init(from codingValue: Int) throws {
            
                }
                public static var singleValueCodingDefaultValue: Int? {
                    1
                }
            }
            """
        )
    }
    
    
//    @SingleValueCodable
//    struct Test6 {
//        @SingleValueCodableDelegate
//        var a: Int
//        var b: Int
//    }
    
    @Test("additional uninitialized properties", .tags(.expansion.singleValueCoding))
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                @SingleValueCodableDelegate
                var a: Int
                var b: Int
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int
                var b: Int
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.singleValueCodable.unhandledRequiredProperties,
                    line: 5,
                    column: 9
                )
            ]
        )
    }
    
    
//    @SingleValueCodable
//    struct Test7 {
//        @SingleValueCodableDelegate
//        var a: Int
//        @SingleValueCodableDelegate
//        var b: Int
//    }
    
    @Test("multiple delegate", .tags(.expansion.singleValueCoding))
    func test7() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                @SingleValueCodableDelegate
                var a: Int
                @SingleValueCodableDelegate
                var b: Int
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int
                var b: Int
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.singleValueCodable.multipleDelegates,
                    line: 1,
                    column: 1
                )
            ]
        )
    }
    
}
