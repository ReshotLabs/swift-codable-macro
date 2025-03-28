//
//  CodableMacroClassTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/22.
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
    
    @Suite("Test Codable macro for special cases")
    final class CodableMacroSpecialTest: CodingExpansionTest {}
    
}



extension CodingExpansionTest.CodableMacroSpecialTest {
    
    @Codable
    struct Test1 {
        
    }
    
    @Test("empty struct")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
            
            }
            """,
            expandedSource: """
            struct Test {
            
            }
            
            extension Test: Codable {
            }
            """
        )
    }
    
    
    @Codable
    class Test2 {
        
    }
    
    @Test("empty class")
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            class Test {
            
            }
            """,
            expandedSource: """
            class Test {
            
                init() {
                }
            
                public required init(from decoder: Decoder) throws {
            
                }
            
                public func encode(to encoder: Encoder) throws {
            
                }
            
            }
            
            extension Test: Codable {
            }
            """
        )
    }
    
    
    @Codable
    final class Test3 {
        
    }
    
    @Test("empty final class")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            final class Test {
            
            }
            """,
            expandedSource: """
            final class Test {
            
            }
            
            extension Test: Codable {
            }
            """
        )
    }
    
    
    @Codable
    struct Test4 {
        var a: Int
        @CodingField("b")
        var b: String
    }
    
    @Test("no actual customization (struct)")
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                var a: Int
                @CodingField("b")
                var b: String
            }
            """,
            expandedSource: """
            struct Test {
                var a: Int
                var b: String
            }
            
            extension Test: Codable {
            }
            """
        )
    }
    
    
    @Codable
    final class Test5 {
        var a: Int
        @CodingField("b")
        var b: String
        init(a: Int, b: String) {
            self.a = a
            self.b = b
        }
    }
    
    @Test("no actual customization (final class)")
    func test5() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            final class Test {
                var a: Int
                @CodingField("b")
                var b: String
                init(a: Int, b: String) {
                    self.a = a
                    self.b = b
                }
            }
            """,
            expandedSource: """
            final class Test {
                var a: Int
                var b: String
                init(a: Int, b: String) {
                    self.a = a
                    self.b = b
                }
            }
            
            extension Test: Codable {
            }
            """
        )
    }
    
    
    @Codable
    class Test6 {
        var a: Int
        init(a: Int) {
            self.a = a
        }
    }
    
    @Test("no actual customization (class)")
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            class Test {
                var a: Int
                init(a: Int) {
                    self.a = a
                }
            }
            """,
            expandedSource: #"""
            class Test {
                var a: Int
                init(a: Int) {
                    self.a = a
                }
            
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
            
                public required init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
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
                    do {
                        let transformedValue = self.a
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            
            extension Test: Codable {
            }
            """#
        )
    }
    
    
    @Codable
    class Test7 {
        var a: Int = 1
    }
    
    @Test("class with all properties initialized")
    func test7() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            class Test {
                var a: Int = 1
            }
            """,
            expandedSource: #"""
            class Test {
                var a: Int = 1
            
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
            
                public required init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    do {
                        let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                        do {
                            let rawValue = try $__coding_container_root.decode(
                                Int.self,
                                forKey: .ka
                            )
                            let value = rawValue
                            self.a = value
                        } catch Swift.DecodingError.typeMismatch {
                        } catch Swift.DecodingError.valueNotFound, Swift.DecodingError.keyNotFound {
                        }
                    } catch Swift.DecodingError.typeMismatch {
                    } catch Swift.DecodingError.keyNotFound {
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
            
                init() {
                }
            }
            
            extension Test: Codable {
            }
            """#
        )
    }
    
    
    @Codable
    final class Test8 {
        var a: Int = 1
    }
    
    @Test("final class with all properties initialized")
    func test8() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            final class Test {
                var a: Int = 1
            }
            """,
            expandedSource: #"""
            final class Test {
                var a: Int = 1
            
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
            
                public required init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    do {
                        let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                        do {
                            let rawValue = try $__coding_container_root.decode(
                                Int.self,
                                forKey: .ka
                            )
                            let value = rawValue
                            self.a = value
                        } catch Swift.DecodingError.typeMismatch {
                        } catch Swift.DecodingError.valueNotFound, Swift.DecodingError.keyNotFound {
                        }
                    } catch Swift.DecodingError.typeMismatch {
                    } catch Swift.DecodingError.keyNotFound {
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
            
                init() {
                }
            }
            
            extension Test: Codable {
            }
            """#
        )
    }
    
    
    @Codable
    class Test9 {
        var a: Int?
    }
    
    @Test("class with all optional type")
    func test9() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            class Test {
                var a: Int?
            }
            """,
            expandedSource: #"""
            class Test {
                var a: Int?
            
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
            
                public required init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    do {
                        let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                        do {
                            let rawValue = try $__coding_container_root.decode(
                                Int?.self,
                                forKey: .ka
                            )
                            let value = rawValue
                            self.a = value
                        } catch Swift.DecodingError.typeMismatch {
                            self.a = nil
                        } catch Swift.DecodingError.valueNotFound, Swift.DecodingError.keyNotFound {
                            self.a = nil
                        }
                    } catch Swift.DecodingError.typeMismatch {
                        self.a = nil
                    } catch Swift.DecodingError.keyNotFound {
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
            
                init() {
                }
            }
            
            extension Test: Codable {
            }
            """#
        )
    }
    
    
    @Codable
    final class Test10 {
        var a: Int?
    }
    
    @Test("final class with all optional type")
    func test10() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            final class Test {
                var a: Int?
            }
            """,
            expandedSource: #"""
            final class Test {
                var a: Int?
            
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
            
                public required init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    do {
                        let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                        do {
                            let rawValue = try $__coding_container_root.decode(
                                Int?.self,
                                forKey: .ka
                            )
                            let value = rawValue
                            self.a = value
                        } catch Swift.DecodingError.typeMismatch {
                            self.a = nil
                        } catch Swift.DecodingError.valueNotFound, Swift.DecodingError.keyNotFound {
                            self.a = nil
                        }
                    } catch Swift.DecodingError.typeMismatch {
                        self.a = nil
                    } catch Swift.DecodingError.keyNotFound {
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
            
                init() {
                }
            }
            
            extension Test: Codable {
            }
            """#
        )
    }
    
    
    class Test11Super: Codable {
        required init() {
            
        }
    }
    
}
