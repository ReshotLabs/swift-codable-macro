//
//  DecodeTransformTest.swift
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


@Suite("Test DecodeTransform macro")
struct DecodeTransformTest {
    
    @Codable
    struct Test1 {
        @DecodeTransform(source: String.self, with: { Int($0)! })
        var a: Int
    }
    
    @Test("closure transform")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @DecodeTransform(source: String.self, with: { Int($0)! })
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
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            String.self,
                            forKey: .ka
                        )
                        let value = try $__coding_transform(rawValue, {
                                Int($0)!
                            })
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let value = self.a
                        let transformedValue = value
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test2 {
        @DecodeTransform(source: String.self, with: \.count)
        var a: Int
    }
    
    @Test("keypath transform")
    func test2() async throws {
        assertMacroExpansion(
            source: #"""
            @Codable
            struct Test {
                @DecodeTransform(source: String.self, with: \.count)
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
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            String.self,
                            forKey: .ka
                        )
                        let value = try $__coding_transform(rawValue, \.count)
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let value = self.a
                        let transformedValue = value
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    static func str2Int(_ input: String) -> Int {
        Int(input)!
    }
    
    @Codable
    struct Test3 {
        @DecodeTransform(source: String.self, with: DecodeTransformTest.str2Int(_:))
        var a: Int
    }
    
    @Test("function transform")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @DecodeTransform(source: String.self, with: DecodeTransformTest.str2Int(_:))
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
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            String.self,
                            forKey: .ka
                        )
                        let value = try $__coding_transform(rawValue, DecodeTransformTest.str2Int(_:))
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let value = self.a
                        let transformedValue = value
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
//    @Codable
//    struct Test4 {
//        @DecodeTransform(source: String.self, with: { $0.lowercased() })
//        @DecodeTransform(source: String.self, with: \.count)
//        var a: Int
//    }
    
    @Test("multiple transform")
    func test4() async throws {
        assertMacroExpansion(
            source: #"""
            @Codable
            struct Test {
                @DecodeTransform(source: String.self, with: { $0.lowercased() })
                @DecodeTransform(source: String.self, with: \.count)
                var a: Int
            }
            """#,
            expandedSource: #"""
            struct Test {
                var a: Int
            }
            """#,
            diagnostics: [
                .init(
                    message: .decorator.general.duplicateMacro(name: "DecodeTransform"),
                    line: 5,
                    column: 9
                )
            ]
        )
    }
    
}
