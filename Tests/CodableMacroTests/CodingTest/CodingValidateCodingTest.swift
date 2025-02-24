//
//  CodingValidateCodingTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/23.
//

import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {
    
    @Suite("Test CodingValidate in Actual Coding", .tags(.coding.keyedCoding))
    final class CodingValidateCodingTest: CodingTest {}
    
}



extension CodingTest.CodingValidateCodingTest {
    
    @Codable
    struct SomeType1: Equatable {
        @CodingValidate(source: Int.self, with: { $0 > 0 })
        @CodingValidate(source: Int.self, with: CodingTest.CodingValidateCodingTest.intIsEven(_:))
        var a: Int
        @CodingValidate(source: String.self, with: \.isNotEmpty)
        var b: String
    }
    
    
    static func intIsEven(_ value: Int) -> Bool {
        return value.isMultiple(of: 2)
    }
    
    
    @Test(
        "Test Decoding",
        arguments: [
            (
                .success(.init(a: 2, b: "Serika")),
                [
                    "a": 2,
                    "b": "Serika"
                ]
            ),
            (
                .error,
                [
                    "a": 1,
                    "b": "Serika"
                ]
            ),
            (
                .error,
                [
                    "a": 0,
                    "b": "Serika"
                ]
            ),
            (
                .error,
                [
                    "a": 2,
                    "b": ""
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
                .init(a: 2, b: "Serika"),
                [
                    "a": 2,
                    "b": "Serika"
                ]
            ),
            (
                .init(a: 1, b: "Serika"),
                [
                    "a": 1,
                    "b": "Serika"
                ]
            ),
            (
                .init(a: 2, b: ""),
                [
                    "a": 2,
                    "b": ""
                ]
            ),
        ] as [(SomeType1, JsonComponent)]
    )
    func encode1(_ instance: SomeType1, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}



extension String {
    fileprivate var isNotEmpty: Bool { !isEmpty }
}
