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
            .doubleDateTransform(),
            IdenticalCodingTransform<Double>(),
            .doubleTypeTransform(option: .string)
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
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let rawValue = try $__coding_container_root.decode(
                            codableMacroStaticType(of: codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string))).TransformedType.self,
                            forKey: .ka
                        )
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
                        let value = self.a
                        let transformedValue1 = try $__coding_transform(value, codingTransformPassThroughWithTypeInference(.doubleDateTransform()).encodeTransform)
                        let transformedValue2 = try $__coding_transform(transformedValue1, codingTransformPassThroughWithTypeInference(IdenticalCodingTransform<Double>()).encodeTransform)
                        let transformedValue = try $__coding_transform(transformedValue2, codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string)).encodeTransform)
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
            .doubleDateTransform(),
            IdenticalCodingTransform<Double>(),
            .doubleTypeTransform(option: .string)
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
                    if let $__coding_container_root = try? decoder.container(keyedBy: $__coding_container_keys_root.self) {
                        do {
                            let rawValue = try? $__coding_container_root.decode(
                                codableMacroStaticType(of: codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string))).TransformedType.self,
                                forKey: .ka
                            )
                            let value1 = rawValue.flatMap({
                                    try? $__coding_transform($0, codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string)).decodeTransform)
                                })
                            let value2 = value1.flatMap({
                                    try? $__coding_transform($0, codingTransformPassThroughWithTypeInference(IdenticalCodingTransform<Double>()).decodeTransform)
                                })
                            let value = value2.flatMap({
                                    try? $__coding_transform($0, codingTransformPassThroughWithTypeInference(.doubleDateTransform()).decodeTransform)
                                })
                            self.a = value ?? .init()
                        }
                    } else {
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        let value = self.a
                        let transformedValue1 = try $__coding_transform(value, codingTransformPassThroughWithTypeInference(.doubleDateTransform()).encodeTransform)
                        let transformedValue2 = try $__coding_transform(transformedValue1, codingTransformPassThroughWithTypeInference(IdenticalCodingTransform<Double>()).encodeTransform)
                        let transformedValue = try $__coding_transform(transformedValue2, codingTransformPassThroughWithTypeInference(.doubleTypeTransform(option: .string)).encodeTransform)
                        try $__coding_container_root.encode(transformedValue, forKey: .ka)
                    }
                }
            }
            """#
        )
    }
    
    
//    @Codable
//    struct Test3 {
//        @CodingTransform
//        var a: Int
//    }
    
    @Test("no argument list")
    func test3() async throws {
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
//    struct Test4 {
//        @CodingTransform()
//        var a: Int
//    }
    
    @Test("no argument")
    func test4() async throws {
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
    
}


struct IdenticalCodingTransform<T>: EvenCodingTransformProtocol {
    func encodeTransform(_ value: T) throws -> T { value }
    func decodeTransform(_ value: T) throws -> T { value }
}
