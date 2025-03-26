//
//  CodingField.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/20.
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
    
    @Suite("Test CodingField macro")
    final class CodingFieldTest: CodingExpansionTest {}
    
}



extension CodingExpansionTest.CodingFieldTest {
    
    @Codable
    struct Test1 {
        @CodingField("path1", "path2", "a")
        var a: Int
    }
    
    
    @Test("var", .tags(.expansion.keyedCoding, .expansion.mutableProperty))
    func test1() async throws {
        
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "path2", "a")
                var a: Int 
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int 
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath1 = "path1"
                }
                enum $__coding_container_keys_root_path1: String, CodingKey {
                    case kpath2 = "path2"
                }
                enum $__coding_container_keys_root_path1_path2: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    let $__coding_container_root_path1 = try $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1.self,
                        forKey: .kpath1
                    )
                    let $__coding_container_root_path1_path2 = try $__coding_container_root_path1.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1_path2.self,
                        forKey: .kpath2
                    )
                    do {
                        let rawValue = try $__coding_container_root_path1_path2.decode(
                            Int.self,
                            forKey: .ka
                        )
                        let value = rawValue
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    var $__coding_container_root_path1 = $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1.self,
                        forKey: .kpath1
                    )
                    var $__coding_container_root_path1_path2 = $__coding_container_root_path1.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1_path2.self,
                        forKey: .kpath2
                    )
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root_path1_path2.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#,
            macroSpecs: testMacros
        )
        
    }
    
    
    @Codable
    struct Test2 {
        @CodingField("path1", "a")
        var a: Int = 1
    }
    
    
    @Test("var | initializer", .tags(.expansion.keyedCoding, .expansion.mutableProperty, .expansion.initializerProperty))
    func test2() async throws {
        
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "a")
                var a: Int = 1
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int = 1
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath1 = "path1"
                }
                enum $__coding_container_keys_root_path1: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    if let $__coding_container_root = try? decoder.container(keyedBy: $__coding_container_keys_root.self) {
                        if let $__coding_container_root_path1 = try? $__coding_container_root.nestedContainer(
                            keyedBy: $__coding_container_keys_root_path1.self,
                            forKey: .kpath1
                        ) {
                            do {
                                let rawValue = try? $__coding_container_root_path1.decode(
                                    Int.self,
                                    forKey: .ka
                                )
                                let value = rawValue
                                self.a = value ?? 1
                            }
                        } else {
                        }
                    } else {
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    var $__coding_container_root_path1 = $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1.self,
                        forKey: .kpath1
                    )
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root_path1.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
        
    }
    
    
    @Codable
    struct Test3 {
        @CodingField("path1", "a")
        var a: Int?
    }
    
    @Test("var | optional", .tags(.expansion.keyedCoding, .expansion.mutableProperty, .expansion.optionalProperty))
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "a")
                var a: Int?
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int?
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath1 = "path1"
                }
                enum $__coding_container_keys_root_path1: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    if let $__coding_container_root = try? decoder.container(keyedBy: $__coding_container_keys_root.self) {
                        if let $__coding_container_root_path1 = try? $__coding_container_root.nestedContainer(
                            keyedBy: $__coding_container_keys_root_path1.self,
                            forKey: .kpath1
                        ) {
                            do {
                                let rawValue = try? $__coding_container_root_path1.decode(
                                    Int?.self,
                                    forKey: .ka
                                )
                                let value = rawValue
                                self.a = value ?? nil
                            }
                        } else {
                            self.a = nil
                        }
                    } else {
                        self.a = nil
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    var $__coding_container_root_path1 = $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1.self,
                        forKey: .kpath1
                    )
                    if let value = self.a {
                        let transformedValue = value
                        try $__coding_container_root_path1.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test5 {
        @CodingField("path1", "a", default: 2)
        var a: Int? = 1
    }
    
    @Test(
        "var | initializer + optional + macro default",
        .tags(.expansion.keyedCoding, .expansion.mutableProperty, .expansion.initializerProperty, .expansion.optionalProperty, .expansion.macroDefaultValue)
    )
    func test5() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "a", default: 2)
                var a: Int? = 1
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int? = 1
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath1 = "path1"
                }
                enum $__coding_container_keys_root_path1: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    if let $__coding_container_root = try? decoder.container(keyedBy: $__coding_container_keys_root.self) {
                        if let $__coding_container_root_path1 = try? $__coding_container_root.nestedContainer(
                            keyedBy: $__coding_container_keys_root_path1.self,
                            forKey: .kpath1
                        ) {
                            do {
                                let rawValue = try? $__coding_container_root_path1.decode(
                                    Int?.self,
                                    forKey: .ka
                                )
                                let value = rawValue
                                self.a = value ?? 2
                            }
                        } else {
                            self.a = 2
                        }
                    } else {
                        self.a = 2
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    var $__coding_container_root_path1 = $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1.self,
                        forKey: .kpath1
                    )
                    if let value = self.a {
                        let transformedValue = value
                        try $__coding_container_root_path1.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test6 {
        @CodingField("path1", "a", default: 1)
        let a: Int
    }
    
    @Test("let | macro default", .tags(.expansion.keyedCoding, .expansion.constantProperty, .expansion.macroDefaultValue))
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "a", default: 1)
                let a: Int
            }
            """,
            expandedSource: #"""
            struct Test {
                let a: Int
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath1 = "path1"
                }
                enum $__coding_container_keys_root_path1: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    if let $__coding_container_root = try? decoder.container(keyedBy: $__coding_container_keys_root.self) {
                        if let $__coding_container_root_path1 = try? $__coding_container_root.nestedContainer(
                            keyedBy: $__coding_container_keys_root_path1.self,
                            forKey: .kpath1
                        ) {
                            do {
                                let rawValue = try? $__coding_container_root_path1.decode(
                                    Int.self,
                                    forKey: .ka
                                )
                                let value = rawValue
                                self.a = value ?? 1
                            }
                        } else {
                            self.a = 1
                        }
                    } else {
                        self.a = 1
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    var $__coding_container_root_path1 = $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path1.self,
                        forKey: .kpath1
                    )
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root_path1.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test8 {
        @CodingField("path", "a")
        var a: Int {
            willSet {}
            didSet {}
        }
        var b: Int { 1 }
    }
    
    @Test("var | computed property", .tags(.expansion.keyedCoding, .expansion.mutableProperty, .expansion.computedProperty))
    func test8() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path", "a")
                var a: Int {
                    willSet {}
                    didSet {}
                }
                var b: Int { 1 }
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Int {
                    willSet {}
                    didSet {}
                }
                var b: Int { 1 }
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath = "path"
                }
                enum $__coding_container_keys_root_path: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    let $__coding_container_root_path = try $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path.self,
                        forKey: .kpath
                    )
                    do {
                        let rawValue = try $__coding_container_root_path.decode(
                            Int.self,
                            forKey: .ka
                        )
                        let value = rawValue
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    var $__coding_container_root_path = $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path.self,
                        forKey: .kpath
                    )
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root_path.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test9 {
        let a: Int = 1
    }
    
    @Test("let | initializer")
    func test9() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                let a: Int = 1
            }
            """,
            expandedSource: #"""
            struct Test {
                let a: Int = 1
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
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
    
    
//    @Codable
//    struct Test10 {
//        @CodingField("path1", "a", default: 1)
//        let a: Int = 1
//    }
    
    @Test("let | initializer + macro default", .tags(.expansion.keyedCoding, .expansion.constantProperty, .expansion.initializerProperty, .expansion.macroDefaultValue))
    func test10() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "a", default: 1)
                let a: Int = 1
            }
            """,
            expandedSource: """
            struct Test {
                let a: Int = 1
            }
            """,
            diagnostics: [
                .init(
                    message: "Default value cannot be specified on a constant with an initializer",
                    line: 3,
                    column: 41
                )
            ]
        )
    }
    
    
//    @Codable
//    struct Test11 {
//        @CodingField("path1", "b", "a")
//        var a: Int
//        @CodingField("path1", "b")
//        var b: String
//    }
    
    @Test("conflict coding path", .tags(.expansion.keyedCoding))
    func test11() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "b", "a")
                var a: Int
                @CodingField("path1", "b")
                var b: String
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int
                var b: String
            }
            """,
            diagnostics: [
                .init(
                    message: #"Property has path that conflict with that of another property"#,
                    line: 6,
                    column: 9,
                    notes: [
                        .init(
                            message: "Any two properties in the same type must not have the same coding path or having path that is a prefix of the the path of the other",
                            line: 6,
                            column: 9
                        ),
                        .init(
                            message: #"conflicted with the path of property "a""#,
                            line: 4,
                            column: 9
                        )
                    ]
                ),
                .init(
                    message: #"path of "b" conflicts with path of this property"#,
                    line: 4,
                    column: 9
                )
            ]
        )
    }
    
    
//    @Codable
//    struct Test12 {
//        @CodingField
//        @CodingField
//        var a: Int
//    }
    
    @Test("multiple CodingField", .tags(.expansion.keyedCoding))
    func test12() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField
                @CodingField
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
                    message: "A stored property should have at most one CodingField macro",
                    line: 5,
                    column: 9
                )
            ]
        )
    }
    
}
