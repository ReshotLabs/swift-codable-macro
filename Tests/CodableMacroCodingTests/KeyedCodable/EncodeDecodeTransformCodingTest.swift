//
//  EncodeDecodeTransformCodingTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/23.
//

import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {
    
    @Suite("Test EncodeTransform & DecodeTransform in Actual Coding", .tags(.coding.keyedCoding))
    final class EncodeDecodeTransformCodingTest: CodingTest {}
    
}



extension CodingTest.EncodeDecodeTransformCodingTest {
    
    @Codable
    struct SomeType1: Equatable {
        @EncodeTransform(source: Int.self, with: \.description)
        @DecodeTransform(
            source: String.self,
            with: {
                guard let value = Int($0) else { throw CocoaError(.coderInvalidValue) }
                return value
            }
        )
        var a: Int
        @EncodeTransform(source: Int.self, with: CodingTest.EncodeDecodeTransformCodingTest.int2Str(_:))
        @DecodeTransform(source: String.self, with: CodingTest.EncodeDecodeTransformCodingTest.str2Int(_:))
        var b: Int
    }
    
    static func str2Int(_ str: String) throws -> Int {
        guard let value = Int(str) else { throw CocoaError(.coderInvalidValue) }
        return value
    }
    
    static func int2Str(_ int: Int) -> String {
        int.description
    }
    
    
    @Test(
        "Test Decoding",
        arguments: [
            (
                .success(.init(a: 1, b: 1)),
                [
                    "a": "1",
                    "b": "1"
                ]
            ),
            (
                .error,
                [
                    "a": 1,
                    "b": "1"
                ]
            ),
            (
                .error,
                [
                    "a": "a",
                    "b": "1"
                ]
            ),
        ] as [(DecodeResult<SomeType1>, JsonComponent)]
    )
    func deocde1(_ expectedInstance: DecodeResult<SomeType1>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Test Encoding",
        arguments: [
            (
                .init(a: 1, b: 1),
                [
                    "a": "1",
                    "b": "1"
                ]
            )
        ] as [(SomeType1, JsonComponent)]
    )
    func encode1(_ instance: SomeType1, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}
