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


extension CodingExpansionTest {
    
    @Suite("Test SingleValueCodable macro", .tags(.expansion.singleValueCoding))
    final class SingleValueCodableTest: CodingExpansionTest {}
    
}



extension CodingExpansionTest.SingleValueCodableTest {
    
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
                public static var singleValueCodingDefaultValue: CodingDefaultValue<Int?> {
                    .value(nil)
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
                public static var singleValueCodingDefaultValue: CodingDefaultValue<Int> {
                    .value(1)
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
                public static var singleValueCodingDefaultValue: CodingDefaultValue<Int> {
                    .value(1)
                }
            }
            """
        )
    }


    @SingleValueCodable
    struct Test6 {
        @SingleValueCodableDelegate(default: 2)
        var a: Int = 1
    }

    @Test(
        "var | delegate | initializer | default value", 
        .tags(.expansion.singleValueCoding, .expansion.mutableProperty, .expansion.initializerProperty, .expansion.macroDefaultValue)
    )
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable
            struct Test {
                @SingleValueCodableDelegate(default: 2)
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
                public static var singleValueCodingDefaultValue: CodingDefaultValue<Int> {
                    .value(2)
                }
            }
            """
        )
    }


    class Test7Base: Codable {}

    @SingleValueCodable(inherit: true)
    class Test7: Test7Base {
        @SingleValueCodableDelegate
        var a: Int 
        init(a: Int) { 
            self.a = a 
            super.init()
        }
    }

    @Test(
        "var | delegate | class | inherit", 
        .tags(.expansion.singleValueCoding, .expansion.mutableProperty)
    )
    func test7() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable(inherit: true)
            class Test: TestBase {
                @SingleValueCodableDelegate
                var a: Int 
                init(a: Int) { 
                    self.a = a 
                    super.init()
                }
            }
            """, 
            expandedSource: """
            class Test: TestBase {
                var a: Int 
                init(a: Int) { 
                    self.a = a 
                    super.init()
                }

                public func singleValueEncode() throws -> Int {
                    return self.a
                }

                public required init(from codingValue: Int, decoder: Decoder) throws {
                    self.a = codingValue
                    try super.init(from: decoder)
                }

                public required init(from decoder: any Decoder) throws {
                    let codingValue = switch Self.singleValueCodingDefaultValue {
                        case .value(let defaultValue):
                            (try? CodingValue(from: decoder)) ?? defaultValue
                        case .none:
                            try CodingValue(from: decoder)
                    }
                    self.a = codingValue
                    try super.init(from: decoder)
                }

                public override func encode(to encoder: any Encoder) throws {
                    try self.singleValueEncode().encode(to: encoder)
                    try super.encode(to: encoder)
                }
            }

            extension Test: InheritedSingleValueCodableProtocol {
            }
            """
        )
    }


    class Test8Base: Codable {
        required init(from decoder: any Decoder) throws {}
        init() {}
    }

    @SingleValueCodable(inherit: true)
    class Test8: Test8Base {
        var a: Int = 1
        init(a: Int) { 
            self.a = a 
            super.init()
        }
        required init(from codingValue: Int, decoder: any Decoder) throws {
            self.a = codingValue
            try super.init(from: decoder)
        }
        func singleValueEncode() throws -> Int {
            return self.a
        }
    }

    @Test(
        "var | class | inherit", 
        .tags(.expansion.singleValueCoding, .expansion.mutableProperty, .expansion.initializerProperty)
    )
    func test8() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable(inherit: true)
            class Test: TestBase {
                var a: Int = 1
                init(a: Int) { 
                    self.a = a 
                    super.init()
                }
                required init(from codingValue: Int, decoder: any Decoder) throws {
                    self.a = codingValue
                    try super.init(from: decoder)
                }
                func singleValueEncode() throws -> Int {
                    return self.a
                }
            }
            """, 
            expandedSource: """
            class Test: TestBase {
                var a: Int = 1
                init(a: Int) { 
                    self.a = a 
                    super.init()
                }
                required init(from codingValue: Int, decoder: any Decoder) throws {
                    self.a = codingValue
                    try super.init(from: decoder)
                }
                func singleValueEncode() throws -> Int {
                    return self.a
                }

                public required init(from decoder: any Decoder) throws {
                    let codingValue = switch Self.singleValueCodingDefaultValue {
                        case .value(let defaultValue):
                            (try? CodingValue(from: decoder)) ?? defaultValue
                        case .none:
                            try CodingValue(from: decoder)
                    }
                    self.a = codingValue
                    try super.init(from: decoder)
                }

                public override func encode(to encoder: any Encoder) throws {
                    try self.singleValueEncode().encode(to: encoder)
                    try super.encode(to: encoder)
                }
            }

            extension Test: InheritedSingleValueCodableProtocol {
            }
            """
        )
    }
    
    
//    @SingleValueCodable
//    struct TestE1 {
//        @SingleValueCodableDelegate
//        var a: Int
//        var b: Int
//    }
    
    @Test("additional uninitialized properties", .tags(.expansion.singleValueCoding))
    func testE1() async throws {
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
    
    
    // @SingleValueCodable
    // struct TestE2 {
    //     @SingleValueCodableDelegate
    //     var a: Int
    //     @SingleValueCodableDelegate
    //     var b: Int
    // }
    
    @Test("multiple delegate", .tags(.expansion.singleValueCoding))
    func testE2() async throws {
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
                    line: 2,
                    column: 8
                )
            ]
        )
    }

    // @SingleValueCodable(inherit: true)
    // struct TestE3 {
    //     @SingleValueCodableDelegate
    //     var a: Int
    // }

    @Test("inherit on value type", .tags(.expansion.singleValueCoding))
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable(inherit: true)
            struct Test {
                @SingleValueCodableDelegate
                var a: Int
            }
            """, 
            expandedSource: """
            struct Test {
                var a: Int
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.singleValueCodable.valueTypeInherit, 
                    line: 1, 
                    column: 30
                )
            ]
        )
    }

    // static var falseBoolValue: Bool { false }

    // @SingleValueCodable(inherit: falseBoolValue)
    // class TestE4 {
    //     @SingleValueCodableDelegate
    //     var a: Int = 1
    // }

    @Test("not bool literal", .tags(.expansion.singleValueCoding))
    func testE4() async throws {
        assertMacroExpansion(
            source: """
            @SingleValueCodable(inherit: falseBoolValue)
            class Test {
                @SingleValueCodableDelegate
                var a: Int = 1
            }
            """, 
            expandedSource: """
            class Test {
                var a: Int = 1
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.singleValueCodable.notBoolLiteralArgument, 
                    line: 1, 
                    column: 30
                )
            ]
        )
    }
    
}