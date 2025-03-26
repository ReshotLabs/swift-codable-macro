//
//  CodingIgnoreTest.swift
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
    
    @Suite("Test CodingIgnore macro")
    final class CodingIgnoreTest: CodingExpansionTest {}
    
}



extension CodingExpansionTest.CodingIgnoreTest {
    
    @Codable
    struct Test1 {
        @CodingField("fielda")
        var a: Int
        @CodingIgnore
        var b: Int = 1
    }
    
    @Test("initializer", .tags(.expansion.initializerProperty))
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("fielda")
                var a: Int
                @CodingIgnore
                var b: Int = 1
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int
                var b: Int = 1
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kfielda = "fielda"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            Int.self,
                            forKey: .kfielda
                        )
                        let value = rawValue
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root.encode(transformedValue, forKey: .kfielda)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test2 {
        @CodingField("fielda")
        var a: Int
        @CodingIgnore
        var b: Int?
    }
    
    @Test("optional", .tags(.expansion.optionalProperty))
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("fielda")
                var a: Int
                @CodingIgnore
                var b: Int?
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int
                var b: Int?
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kfielda = "fielda"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            Int.self,
                            forKey: .kfielda
                        )
                        let value = rawValue
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root.encode(transformedValue, forKey: .kfielda)
                    }
                }
            }
            """#
        )
    }
    
    
//    @Codable
//    struct Test3 {
//        @CodingField("fielda")
//        var a: Int
//        @CodingIgnore
//        var b: Int
//    }
    
    
    @Test("not ignoreable")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("fielda")
                var a: Int
                @CodingIgnore
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
                    message: "The property can only be ignored when it has a default value or is optional",
                    line: 6,
                    column: 9
                )
            ]
        )
    }
    
}
