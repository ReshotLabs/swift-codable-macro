//
//  CodingTransformCodingTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/23.
//

import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {
    
    @Suite("Test CodingIgnore in Actual Coding", .tags(.coding.keyedCoding))
    final class CodingTransformCodingTest: CodingTest {}
    
}



extension CodingTest.CodingTransformCodingTest {
    
    @Codable
    struct SomeType1: Equatable {
        @CodingTransform(.date.iso8601FormatTransform)
        var a: Date
        @CodingTransform(.date.timeIntervalTransform(), .double.multiRepresentationTransform(encodeTo: .string))
        var b: Date
        @CodingTransform(.bool.multiRepresentationTransform(encodeTo: .customString(true: "T", false: "F")))
        var c: Bool
        @CodingTransform(.data.base64Transform())
        var d: Data
        @CodingTransform(
            CustomCodingTransform<Int, String>(
                encode: { ($0 + 1).description },
                decode: { Int($0)! - 1 }
            )
        )
        var e: Int
    }
    
    
    static var testingDate: Date {
        Calendar.current.date(
            from: .init(
                timeZone: .init(secondsFromGMT: 0),
                year: 2025,
                month: 2,
                day: 10,
                hour: 18,
                second: 30
            )
        )!
    }
    
    static var testingDateISO8601Str: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: testingDate)
    }
    
    
    @Test(
        "Test Decoding",
        arguments: [
            (
                .success(.init(a: testingDate, b: testingDate, c: false, d: .init("Serika".utf8), e: 1)),
                [
                    "a": .string(testingDateISO8601Str),
                    "b": .real(testingDate.timeIntervalSince1970),
                    "c": .string("F"),
                    "d": .string(Data("Serika".utf8).base64EncodedString()),
                    "e": .string("2")
                ]
            ),
            (
                .error,
                [
                    "a": .string("not iso8601"),
                    "b": .real(testingDate.timeIntervalSince1970),
                    "c": .string("F"),
                    "d": .string(Data("Serika".utf8).base64EncodedString()),
                    "e": .string("2")
                ]
            ),
            (
                .error,
                [
                    "a": .string(testingDateISO8601Str),
                    "b": .string(testingDateISO8601Str),
                    "c": .string("F"),
                    "d": .string(Data("Serika".utf8).base64EncodedString()),
                    "e": .string("2")
                ]
            ),
            (
                .error,
                [
                    "a": .string(testingDateISO8601Str),
                    "b": .real(testingDate.timeIntervalSince1970),
                    "c": .string("false"),
                    "d": .string(Data("Serika".utf8).base64EncodedString()),
                    "e": .string("2")
                ]
            ),
            (
                .error,
                [
                    "a": .string(testingDateISO8601Str),
                    "b": .real(testingDate.timeIntervalSince1970),
                    "c": .string("F"),
                    "d": 1,
                    "e": .string("2")
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
                .init(a: testingDate, b: testingDate, c: false, d: .init("Serika".utf8), e: 1),
                [
                    "a": .string(testingDateISO8601Str),
                    "b": .string(testingDate.timeIntervalSince1970.description),
                    "c": .string("F"),
                    "d": .string(Data("Serika".utf8).base64EncodedString()),
                    "e": .string("2")
                ]
            ),
        ] as [(SomeType1, JsonComponent)]
    )
    func encode1(_ instance: SomeType1, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}
