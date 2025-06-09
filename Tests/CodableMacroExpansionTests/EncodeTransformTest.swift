//
//  EncodeTransformTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/21.
//

import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport

@testable import CodableMacro

#if canImport(CodableMacroMacros)
@testable import CodableMacroMacros
#endif


extension CodingExpansionTest {
    
    @Suite("Test EncodeTransform macro")
    final class EncodeTransformTest: CodingExpansionTest {}
    
}



extension CodingExpansionTest.EncodeTransformTest {
    
    @Codable
    struct Test1 {
        @EncodeTransform(source: Int.self, with: { $0.description })
        var a: Int
    }
    
    @Test("closure transform")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @EncodeTransform(source: Int.self, with: { $0.description })
                var a: Int
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(Int.self, forKey: .ka)
                        let value = rawValue
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = try $__coding_transform(self.a, {
                                $0.description
                            })
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test2 {
        @EncodeTransform(source: Int.self, with: \.description)
        var a: Int
    }
    
    @Test("keypath transform")
    func test2() async throws {
        assertMacroExpansion(
            source: #"""
            @Codable
            struct Test {
                @EncodeTransform(source: Int.self, with: \.description)
                var a: Int
            }
            """#,
            expandedSource: #"""
            struct Test {
                var a: Int
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(Int.self, forKey: .ka)
                        let value = rawValue
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = try $__coding_transform(self.a, \.description)
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    static func int2Str(_ int: Int) -> String {
        int.description
    }
    
    @Codable
    struct Test3 {
        @EncodeTransform(source: Int.self, with: CodingExpansionTest.EncodeTransformTest.int2Str(_:))
        var a: Int
    }
    
    @Test("function transform")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @EncodeTransform(source: Int.self, with: CodingExpansionTest.EncodeTransformTest.int2Str(_:))
                var a: Int
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(Int.self, forKey: .ka)
                        let value = rawValue
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = try $__coding_transform(self.a, CodingExpansionTest.EncodeTransformTest.int2Str(_:))
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
//    @Codable
//    struct Test4 {
//        @EncodeTransform(source: Int.self, with: { $0 + 1 })
//        @EncodeTransform(source: Int.self, with: \.description)
//        var a: Int
//    }
    
    @Test("multiple transform")
    func test4() async throws {
        assertMacroExpansion(
            source: #"""
            @Codable
            struct Test {
                @EncodeTransform(source: Int.self, with: { $0 + 1 })
                @EncodeTransform(source: Int.self, with: \.description)
                var a: Int
            }
            """#,
            expandedSource: """
            struct Test {
                var a: Int
            }
            """,
            diagnostics: [
                .init(
                    message: .decorator.general.duplicateMacro(name: "EncodeTransform"),
                    line: 3,
                    column: 5
                ),
                .init(
                    message: .decorator.general.duplicateMacro(name: "EncodeTransform"),
                    line: 4,
                    column: 5
                )
            ]
        )
    }
    
}
