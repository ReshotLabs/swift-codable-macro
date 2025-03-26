//
//  CodingValidateTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/21.
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
    
    @Suite("Test CodingValidate macro")
    final class CodingValidateTest: CodingExpansionTest {}
    
}



extension CodingExpansionTest.CodingValidateTest {
    
    @Codable
    struct Test1 {
        @CodingValidate(
            source: Int.self,
            with: {
                print("test")
                return $0 > 0
            }
        )
        var a: Int
    }
    
    @Test("multi-line validation")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingValidate(
                    source: Int.self, 
                    with: { 
                        print("test")
                        return $0 > 0 
                    }
                )
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
                            Int.self,
                            forKey: .ka
                        )
                        let value = rawValue
                        try $__coding_validate("a", #"{\#("\\#n")    print("test")\#("\\#n")    return $0 > 0\#("\\#n")}"#, value, {
                                    print("test")
                                    return $0 > 0
                                })
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test2 {
        @CodingValidate(source: Int.self, with: { $0 > 0 })
        @CodingValidate(source: Int.self, with: \.description.isEmpty)
        var a: Int?
    }
    
    @Test("multiple validation")
    func test2() async throws {
        assertMacroExpansion(
            source: #"""
            @Codable
            struct Test {
                @CodingValidate(source: Int.self, with: { $0 > 0 })
                @CodingValidate(source: Int.self, with: \.description.isEmpty)
                var a: Int?
            }
            """#,
            expandedSource: #"""
            struct Test {
                var a: Int?
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    if let $__coding_container_root = try? decoder.container(keyedBy: $__coding_container_keys_root.self) {
                        do {
                            let rawValue = try? $__coding_container_root.decode(
                                Int?.self,
                                forKey: .ka
                            )
                            let value = rawValue
                            if let value {
                                try $__coding_validate("a", "{\n    $0 > 0\n}", value, {
                                        $0 > 0
                                    })
                                try $__coding_validate("a", #"\.description.isEmpty"#, value, \.description.isEmpty)
                            }
                            self.a = value ?? nil
                        }
                    } else {
                        self.a = nil
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    if let value = self.a {
                        let transformedValue = value
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
}
