//
//  CodingTransformTest.swift
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
    
    @Suite("Test CodingTransform macro")
    final class CodingTransformTest: CodingExpansionTest {}
    
}



extension CodingExpansionTest.CodingTransformTest {
    
    @Codable
    struct Test1 {
        @CodingTransform(
            .date.timeIntervalTransform(),
            IdenticalCodingTransform<Double>(),
            .double.multiRepresentationTransform(encodeTo: .string)
        )
        var a: Date
    }
    
    @Test("normal property")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingTransform(
                    .doubleDateTransform(),
                    IdenticalCodingTransform<Double>(),
                    .doubleTypeTransform(option: .string)
                )
                var a: Date
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Date
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
                        let rawValue = try $__coding_container_root.decode(codableMacroStaticType(of: codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string))).TransformedType.self, forKey: .ka)
                        let value1 = try $__coding_transform(rawValue, codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string)).decodeTransform)
                        let value2 = try $__coding_transform(value1, codingTransformPassThroughWithTypeInference(IdenticalCodingTransform<Double>()).decodeTransform)
                        let value = try $__coding_transform(value2, codingTransformPassThroughWithTypeInference(.doubleDateTransform()).decodeTransform)
                        self.a = value
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let value1 = try $__coding_transform(self.a, codingTransformPassThroughWithTypeInference(.doubleDateTransform()).encodeTransform)
                        let value2 = try $__coding_transform(value1, codingTransformPassThroughWithTypeInference(IdenticalCodingTransform<Double>()).encodeTransform)
                        let transformedValue = try $__coding_transform(value2, codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string)).encodeTransform)
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
    @Codable
    struct Test2 {
        @CodingTransform(
            .date.timeIntervalTransform(),
            IdenticalCodingTransform<Double>(),
            .double.multiRepresentationTransform(encodeTo: .string)
        )
        var a: Date? = .init()
    }
    
    @Test("optional + initializer", .tags(.expansion.optionalProperty, .expansion.initializerProperty))
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingTransform(
                    .doubleDateTransform(),
                    IdenticalCodingTransform<Double>(),
                    .doubleTypeTransform(option: .string)
                )
                var a: Date = .init()
            }
            """,
            expandedSource: #"""
            struct Test {
                var a: Date = .init()
            }
            
            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    do {
                        let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                        do {
                            let rawValue = try $__coding_container_root.decode(codableMacroStaticType(of: codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string))).TransformedType.self, forKey: .ka)
                            let value1 = try $__coding_transform(rawValue, codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string)).decodeTransform)
                            let value2 = try $__coding_transform(value1, codingTransformPassThroughWithTypeInference(IdenticalCodingTransform<Double>()).decodeTransform)
                            let value = try $__coding_transform(value2, codingTransformPassThroughWithTypeInference(.doubleDateTransform()).decodeTransform)
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
                        let value1 = try $__coding_transform(self.a, codingTransformPassThroughWithTypeInference(.doubleDateTransform()).encodeTransform)
                        let value2 = try $__coding_transform(value1, codingTransformPassThroughWithTypeInference(IdenticalCodingTransform<Double>()).encodeTransform)
                        let transformedValue = try $__coding_transform(value2, codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string)).encodeTransform)
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
//    @Codable
//    struct TestE1 {
//        @CodingTransform
//        var a: Int
//    }
    
    @Test("no argument list")
    func testE1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingTransform
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
                    message: .decorator.general.noArguments(),
                    line: 3,
                    column: 5
                )
            ]
        )
    }
    
    
//    @Codable
//    struct TestE2 {
//        @CodingTransform()
//        var a: Int
//    }
    
    @Test("no argument")
    func testE2() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingTransform()
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
                    message: .argumentParsing.notMatch(rule: .varArg(), argumentIndex: 0),
                    line: 3,
                    column: 22
                )
            ]
        )
    }


    // @Codable
    // struct TestE3 {
    //     @CodingTransform(
    //         .intTypeTransform(option: .string)
    //     )
    //     @DecodeTransform(source: String.self, with: { Int($0)! })
    //     var a: Int
    // }

    @Test("conflicted with DecodeTransform")
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingTransform(
                    .intTypeTransform(option: .string)
                )
                @DecodeTransform(source: String.self, with: { Int($0)! })
                var a: Int
            }
            """, 
            expandedSource: """
            struct Test {
                var a: Int
            }
            """,
            diagnostics: [
                .init(message: .codingMacro.general.conflictDecorators(.codingTransform, .decodeTransform), line: 3, column: 5),
                .init(message: .codingMacro.general.conflictDecorators(.codingTransform, .decodeTransform), line: 6, column: 5)
            ]
        )
    }
    
}


struct IdenticalCodingTransform<T>: EvenCodingTransformProtocol {
    func encodeTransform(_ value: T) throws -> T { value }
    func decodeTransform(_ value: T) throws -> T { value }
}
