//
//  CodingIgnoreCodingTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/23.
//

import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {
    
    @Suite("Test CodingIgnore in Actual Coding", .tags(.coding.keyedCoding))
    final class CodingIgnoreCodingTest: CodingTest {}
    
}


extension CodingTest.CodingIgnoreCodingTest {
    
    @Codable
    struct SomeType1: Equatable {
        var a: Int
        @CodingIgnore
        var b: Int?
        @CodingIgnore
        var c: Int = 1
    }
    
    
    @Test(
        "Test Decoding",
        arguments: [
            (
                .success(.init(a: 1, b: nil, c: 1)),
                [
                    "a": 1,
                    "path1": [
                        "b": 1,
                        "path2": [ "c": 2 ]
                    ],
                    "b": 2
                ]
            ),
            (
                .success(.init(a: 1, b: nil, c: 1)),
                [
                    "a": 1,
                    "path1": [
                        "b": "1",
                        "path2": [ "d": 2 ]
                    ],
                    "b": 2
                ]
            ),
            (
                .error,
                [
                    "a": "1",
                    "path1": [
                        "b": 1,
                        "path2": [ "c": 1 ]
                    ],
                    "b": 2
                ]
            )
        ] as [(DecodeResult<SomeType1>, JsonComponent)]
    )
    func deocde1(_ expectedInstance: DecodeResult<SomeType1>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Test Encoding",
        arguments: [
            (
                .init(a: 1, b: 1, c: 1),
                [ "a": 1 ]
            ),
            (
                .init(a: 1, b: nil, c: 2),
                [ "a": 1 ]
            )
        ] as [(SomeType1, JsonComponent)]
    )
    func encode1(_ instance: SomeType1, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}
