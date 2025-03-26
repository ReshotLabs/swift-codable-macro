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

    @Suite("Test Codable Inheritance")
    class CodableInheritanceTest: CodingExpansionTest {}

}



extension CodingExpansionTest.CodableInheritanceTest {

    class Base: Codable {
        var a: Int
    }

    @Codable(inherit: true)
    class Test1: Base {
        var b: Int
    }


    @Test("Non Final")
    func test1() async throws {
        
        assertMacroExpansion(
            source: """
            @Codable(inherit: true)
            class Test1: Base {
                var b: Int
            }
            """, 
            expandedSource: #"""
            class Test1: Base {
                var b: Int

                enum $__coding_container_keys_root: String, CodingKey {
                    case kb = "b"
                }
            
                public required init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            Int.self,
                            forKey: .kb
                        )
                        let value = rawValue
                        self.b = value
                    }
                    try super.init(from: decoder)
                }
            
                public override func encode(to encoder: Encoder) throws {
                    try super.encode(to: encoder)
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = self.b
                        try $__coding_container_root.encode(transformedValue, forKey: .kb)
                    }
                }
            }

            extension Test1 {
            }
            """#,
            macroSpecs: testMacros
        )

    }


    @Codable(inherit: true)
    final class Test2: Base {
        var c: Int
    }

    @Test("Final")
    func test2() async throws {
        
        assertMacroExpansion(
            source: """
            @Codable(inherit: true)
            final class Test2: Base {
                var c: Int
            }
            """, 
            expandedSource: #"""
            final class Test2: Base {
                var c: Int

                enum $__coding_container_keys_root: String, CodingKey {
                    case kc = "c"
                }

                public required init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            Int.self,
                            forKey: .kc
                        )
                        let value = rawValue
                        self.c = value
                    }
                    try super.init(from: decoder)
                }

                public override func encode(to encoder: Encoder) throws {
                    try super.encode(to: encoder)
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let transformedValue = self.c
                        try $__coding_container_root.encode(transformedValue, forKey: .kc)
                    }
                }
            }

            extension Test2 {
            }
            """#
        )

    }

}


