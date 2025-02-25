//
//  CodingFieldCodingTest.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/11.
//

import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {
    
    @Suite("Test CodingField in Actual Coding", .tags(.coding.keyedCoding))
    final class CodingFieldCodingTest: CodingTest {}
    
}


extension CodingTest.CodingFieldCodingTest {
    
    @Codable
    struct SomeType1: Equatable {
        var a: Int
        @CodingField("path1", "b")
        var b: Int?
        @CodingField("path1", "path2", "c")
        var c: Int = 2
        @CodingField("path2", "d", default: 2)
        var d: Int? = 1
    }
    
    @Test(
        "Test Decoding",
        arguments: [
            (
                .success(.init(a: 1, b: 1, c: 1, d: 1)),
                [
                    "a": 1,
                    "path1": [
                        "b": 1,
                        "path2": [ "c": 1 ]
                    ],
                    "path2": ["d": 1],
                    "b": 2
                ]
            ),
            (
                .success(.init(a: 1, b: nil, c: 2, d: 2)),
                [
                    "a": 1,
                    "path1": [
                        "b": "1",
                        "path1": [ "c": 1 ]
                    ],
                    "path2": ["e": 1],
                    "d": 3
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
                    "path2": ["d": 1],
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
                .init(a: 1, b: 1, c: 1, d: 1),
                [
                    "a": 1,
                    "path1": [
                        "b": 1,
                        "path2": [ "c": 1 ]
                    ],
                    "path2": ["d": 1]
                ]
            ),
            (
                .init(a: 1, b: nil, c: 2, d: 2),
                [
                    "a": 1,
                    "path1": [
                        "path2": [ "c": 2 ]
                    ],
                    "path2": ["d": 2]
                ]
            )
        ] as [(SomeType1, JsonComponent)]
    )
    func encode1(_ instance: SomeType1, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}
