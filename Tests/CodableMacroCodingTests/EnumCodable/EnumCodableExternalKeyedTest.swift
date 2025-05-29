import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {

    @Suite("Test EnumCodable (External Keyed) in Actual Coding")
    final class EnumCodableExternalKeyedTest: CodingTest {}

}



extension CodingTest.EnumCodableExternalKeyedTest {

    @EnumCodable(option: .externalKeyed)
    enum Test: Equatable {

        case a

        @EnumCaseCoding(key: "key_b", emptyPayloadOption: .nothing)
        case b

        @EnumCaseCoding(emptyPayloadOption: .emptyArray)
        case c

        @EnumCaseCoding(emptyPayloadOption: .emptyObject)
        case d

        case e(value: Int)

        @EnumCaseCoding(key: "key_f", payload: .array)
        case f(value: Int, _: String)

        case g(value: Int, _: String)
        
        @EnumCaseCoding(key: "key_h", payload: .object(keys: "key1", "key2"))
        case h(value: Int, _: String)

    }


    @Test(
        "Test Decoding (success)",
        arguments: [
            (
                .success(.a),
                [
                    "a": nil
                ]
            ),
            (
                .success(.b),
                "key_b"
            ),
            (
                .success(.c),
                [
                    "c": []
                ]
            ),
            (
                .success(.d),
                [
                    "d": [:]
                ]
            ),
            (
                .success(.e(value: 1)),
                [
                    "e": 1
                ]
            ),
            (
                .success(.f(value: 1, "f")),
                [
                    "key_f": [1, "f"]
                ]
            ),
            (
                .success(.g(value: 1, "g")),
                [
                    "g": [
                        "value": 1,
                        "_1": "g"
                    ]
                ]
            ),
            (
                .success(.h(value: 1, "h")),
                [
                    "key_h": [
                        "key1": 1,
                        "key2": "h"
                    ]
                ]
            ),
        ] as [(DecodeResult<Test>, JsonComponent)]
    )
    func test1(_ expectedInstance: DecodeResult<Test>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }


    @Test(
        "Test Decoding (failure)",
        arguments: [
            (
                .error,
                [
                    "key_not_exist"
                ]
            ),
            (
                .error,
                "a"
            ),
            (
                .error,
                [
                    "a": 1
                ]
            ),
            (
                .error,
                [
                    "key_b": nil
                ]
            ),
            (
                .error,
                [
                    "c": [:]
                ]
            ),
            (
                .error,
                [
                    "d": []
                ]
            ),
            (
                .error,
                [
                    "e": [ "value": 1 ]
                ]
            ),
            (
                .error,
                [
                    "key_f": [1]
                ]
            ),
            (
                .error,
                [
                    "g": [ "value": "1", "_1": "h" ]
                ]
            ),
            (
                .error,
                [
                    "key_h": [ "value": 1, "_1": "h" ]
                ]
            ),
        ] as [(DecodeResult<Test>, JsonComponent)]
    )
    func test2(_ expectedInstance: DecodeResult<Test>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }

}



extension CodingTest.EnumCodableExternalKeyedTest {

    @Test(
        "Test Encoding 1",
        arguments: [
            (
                .a,
                [
                    "a": nil
                ]
            ),
            (
                .b,
                "key_b"
            ),
            (
                .c,
                [
                    "c": []
                ]
            ),
            (
                .d,
                [
                    "d": [:]
                ]
            ),
            (
                .e(value: 1),
                [
                    "e": 1
                ]
            ),
            (
                .f(value: 1, "f"),
                [
                    "key_f": [1, "f"]
                ]
            ),
            (
                .g(value: 1, "g"),
                [
                    "g": [
                        "value": 1,
                        "_1": "g"
                    ]
                ]
            ),
            (
                .h(value: 1, "h"),
                [
                    "key_h": [
                        "key1": 1,
                        "key2": "h"
                    ]
                ]
            ),
        ] as [(Test, JsonComponent)]
    )
    func test3(_ instance: Test, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }

}