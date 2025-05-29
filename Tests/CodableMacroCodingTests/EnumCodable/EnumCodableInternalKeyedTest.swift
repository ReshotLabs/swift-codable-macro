import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {

    @Suite("Test EnumCodable (Internal Keyed) in Actual Coding")
    final class EnumCodableInternalKeyedTest: CodingTest {}

}



extension CodingTest.EnumCodableInternalKeyedTest {

    @EnumCodable(option: .internalKeyed(typeKey: "case"))
    enum Test: Equatable {

        case a

        @EnumCaseCoding(key: "key_b", emptyPayloadOption: .nothing)
        case b

        @EnumCaseCoding(key: 0x3)
        case c

        @EnumCaseCoding(key: 4.1)
        case d

        case e(value: Int)

        case f(value: Int, _: String)

        @EnumCaseCoding(key: "key_g", payload: .object)
        case g(value: Int)

        @EnumCaseCoding(key: 8, payload: .object(keys: "key1", "key2"))
        case h(value: Int, _: String)

    }


    @Test(
        "Test Decoding (success)",
        arguments: [
            (
                .success(.a),
                [
                    "case": "a"
                ]
            ),
            (
                .success(.b),
                [
                    "case": "key_b"
                ]
            ),
            (
                .success(.c),
                [
                    "case": 3
                ]
            ),
            (
                .success(.d),
                [
                    "case": 4.1
                ]
            ),
            (
                .success(.e(value: 10)),
                [
                    "case": "e",
                    "value": 10
                ]
            ),
            (
                .success(.f(value: 20, "test")),
                [
                    "case": "f",
                    "value": 20,
                    "_1": "test"
                ]
            ),
            (
                .success(.g(value: 30)),
                [
                    "case": "key_g",
                    "value": 30
                ]
            ),
            (
                .success(.h(value: 40, "example")),
                [
                    "case": 8,
                    "key1": 40,
                    "key2": "example"
                ]
            )
        ] as [(DecodeResult<Test>, JsonComponent)]
    )
    func test1(_ expectedInstance: DecodeResult<Test>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }


    @Test(
        "Test Decoding (failure)",
        arguments: [
            "a",
            [
                "type": "a"
            ],
            [
                "case": "???"
            ],
            [
                "case": 0x1
            ],
            [
                "case": "3"
            ],
            [
                "case": 4.11
            ],
            [
                "case": "e",
                "value": "1"
            ],
            [
                "case": "f",
                "value": 10,
                "_0": "test"
            ],
            [
                "case": "key_g",
                "value": [1]
            ],
            [
                "case": 8,
                "payload": [
                    "key1": 40,
                    "key2": "example"
                ]
            ]
        ] as [JsonComponent]
    )
    func test2(_ json: JsonComponent) async throws {
        try codingTestDecodeAssert(DecodeResult<Test>.error, json)
    }

}



extension CodingTest.EnumCodableInternalKeyedTest {

    @Test(
        "Test Encoding",
        arguments: [
            (
                .a,
                [
                    "case": "a"
                ]
            ),
            (
                .b,
                [
                    "case": "key_b"
                ]
            ),
            (
                .c,
                [
                    "case": 3
                ]
            ),
            (
                .d,
                [
                    "case": 4.1
                ]
            ),
            (
                .e(value: 10),
                [
                    "case": "e",
                    "value": 10
                ]
            ),
            (
                .f(value: 20, "test"),
                [
                    "case": "f",
                    "value": 20,
                    "_1": "test"
                ]
            ),
            (
                .g(value: 30),
                [
                    "case": "key_g",
                    "value": 30
                ]
            ),
            (
                .h(value: 40, "example"),
                [
                    "case": 8,
                    "key1": 40,
                    "key2": "example"
                ]
            )
        ] as [(Test, JsonComponent)]
    )
    func test3(_ instance: Test, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }

}