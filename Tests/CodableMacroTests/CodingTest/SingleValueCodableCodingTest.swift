//
//  SingleValueCodableCodingTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/23.
//

import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {
    
    @Suite("Test SingleValueCodable in Actual Coding", .tags(.coding.singleValueCoding))
    final class SingleValueCodableCodingTest: CodingTest {}
    
}



extension CodingTest.SingleValueCodableCodingTest {
    
    @SingleValueCodable
    struct SomeType1: Equatable {
        var a: Int
        init(a: Int) { self.a = a }
        init(from codingValue: Int) throws { self.a = codingValue }
        func singleValueEncode() throws -> Int { self.a }
    }
    
    
    @Test(
        "Decode with customization",
        arguments: [
            (
                .success(.init(a: 1)),
                .int(1)
            ),
            (
                .error,
                .string("1")
            ),
            (
                .error,
                .object([:])
            ),
            (
                .error,
                .object([ "a": 1 ])
            ),
        ] as [(DecodeResult<SomeType1>, JsonComponent)]
    )
    func deocde1(_ expectedInstance: DecodeResult<SomeType1>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Encode with customization",
        arguments: [
            (
                .init(a: 1),
                .int(1)
            )
        ] as [(SomeType1, JsonComponent)]
    )
    func encode1(_ instance: SomeType1, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}



extension CodingTest.SingleValueCodableCodingTest {
    
    @SingleValueCodable
    struct SomeType2: Equatable {
        var a: Int
        static let singleValueCodingDefaultValue: Int? = 2
        init(a: Int) { self.a = a }
        init(from codingValue: Int) throws { self.a = codingValue }
        func singleValueEncode() throws -> Int { self.a }
    }
    
    
    @Test(
        "Decode with customization + default value",
        arguments: [
            (
                .success(.init(a: 1)),
                .int(1)
            ),
            (
                .success(.init(a: 2)),
                .string("1")
            ),
            (
                .success(.init(a: 2)),
                .object([:])
            ),
            (
                .success(.init(a: 2)),
                .object([ "a": 1 ])
            ),
        ] as [(DecodeResult<SomeType2>, JsonComponent)]
    )
    func deocde2(_ expectedInstance: DecodeResult<SomeType2>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Encode with customization + default value",
        arguments: [
            (
                .init(a: 1),
                .int(1)
            )
        ] as [(SomeType2, JsonComponent)]
    )
    func encode2(_ instance: SomeType2, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}



extension CodingTest.SingleValueCodableCodingTest {
    
    @SingleValueCodable
    struct SomeType3: Equatable {
        var a: Int?
        static let singleValueCodingDefaultValue: Int?? = .some(nil)
        init(a: Int?) { self.a = a }
        init(from codingValue: Int?) throws { self.a = codingValue }
        func singleValueEncode() throws -> Int? { self.a }
    }
    
    
    @Test(
        "Decode with customization + optional",
        arguments: [
            (
                .success(.init(a: 1)),
                .int(1)
            ),
            (
                .success(.init(a: nil)),
                .string("1")
            ),
            (
                .success(.init(a: nil)),
                .object([:])
            ),
            (
                .success(.init(a: nil)),
                .object([ "a": 1 ])
            ),
        ] as [(DecodeResult<SomeType3>, JsonComponent)]
    )
    func deocde3(_ expectedInstance: DecodeResult<SomeType3>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Encode with customization + optional",
        arguments: [
            (
                .init(a: 1),
                .int(1)
            )
        ] as [(SomeType3, JsonComponent)]
    )
    func encode3(_ instance: SomeType3, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}



extension CodingTest.SingleValueCodableCodingTest {
    
    @SingleValueCodable
    struct SomeType4: Equatable {
        @SingleValueCodableDelegate
        var a: Int
    }
    
    
    @Test(
        "Decode with delegate",
        arguments: [
            (
                .success(.init(a: 1)),
                .int(1)
            ),
            (
                .error,
                .string("1")
            ),
            (
                .error,
                .object([:])
            ),
            (
                .error,
                .object([ "a": 1 ])
            ),
        ] as [(DecodeResult<SomeType4>, JsonComponent)]
    )
    func deocde4(_ expectedInstance: DecodeResult<SomeType4>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Encode with delegate",
        arguments: [
            (
                .init(a: 1),
                .int(1)
            )
        ] as [(SomeType4, JsonComponent)]
    )
    func encode4(_ instance: SomeType4, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}



extension CodingTest.SingleValueCodableCodingTest {
    
    @SingleValueCodable
    struct SomeType5: Equatable {
        @SingleValueCodableDelegate
        var a: Int = 2
    }
    
    
    @Test(
        "Decode with delegate + initializer",
        arguments: [
            (
                .success(.init(a: 1)),
                .int(1)
            ),
            (
                .success(.init(a: 2)),
                .string("1")
            ),
            (
                .success(.init(a: 2)),
                .object([:])
            ),
            (
                .success(.init(a: 2)),
                .object([ "a": 1 ])
            ),
        ] as [(DecodeResult<SomeType5>, JsonComponent)]
    )
    func deocde5(_ expectedInstance: DecodeResult<SomeType5>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Encode with delegate + initializer",
        arguments: [
            (
                .init(a: 1),
                .int(1)
            )
        ] as [(SomeType5, JsonComponent)]
    )
    func encode5(_ instance: SomeType5, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}



extension CodingTest.SingleValueCodableCodingTest {
    
    @SingleValueCodable
    struct SomeType6: Equatable {
        @SingleValueCodableDelegate
        var a: Int?
    }
    
    
    @Test(
        "Decode with delegate + optional",
        arguments: [
            (
                .success(.init(a: 1)),
                .int(1)
            ),
            (
                .success(.init(a: nil)),
                .string("1")
            ),
            (
                .success(.init(a: nil)),
                .object([:])
            ),
            (
                .success(.init(a: nil)),
                .object([ "a": 1 ])
            ),
        ] as [(DecodeResult<SomeType6>, JsonComponent)]
    )
    func deocde6(_ expectedInstance: DecodeResult<SomeType6>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Encode with delegate + optional",
        arguments: [
            (
                .init(a: 1),
                .int(1)
            )
        ] as [(SomeType6, JsonComponent)]
    )
    func encode6(_ instance: SomeType6, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}



extension CodingTest.SingleValueCodableCodingTest {
    
    @SingleValueCodable
    struct SomeType7: Equatable {
        @SingleValueCodableDelegate
        let a: Int = 2
    }
    
    
    @Test(
        "Decode with delegate + constant + initializer",
        arguments: [
            (
                .success(.init()),
                .int(1)
            ),
            (
                .success(.init()),
                .string("1")
            ),
            (
                .success(.init()),
                .object([:])
            ),
            (
                .success(.init()),
                .object([ "a": 1 ])
            ),
        ] as [(DecodeResult<SomeType7>, JsonComponent)]
    )
    func deocde6(_ expectedInstance: DecodeResult<SomeType7>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    
    @Test(
        "Encode with delegate + constant + initializer",
        arguments: [
            (
                .init(),
                .int(2)
            )
        ] as [(SomeType7, JsonComponent)]
    )
    func encode6(_ instance: SomeType7, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}
