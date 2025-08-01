import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {

    @Suite("Test EnumCodable (Adjacent Keyed) in Actual Coding")
    final class EnumCodableAdjacentKeyedTest: CodingTest {}

}



extension CodingTest.EnumCodableAdjacentKeyedTest {

    @EnumCodable(option: .adjucentKeyed(payloadField: "content"))
    enum Test: Equatable {

        case a

        @EnumCaseCoding(caseKey: "key_b", emptyPayloadOption: .null)
        case b

        @EnumCaseCoding(caseKey: 0x3, emptyPayloadOption: .emptyArray)
        case c

        @EnumCaseCoding(caseKey: 4.1, emptyPayloadOption: .emptyObject)
        case d

        case e(value: Int)

        case f(value: Int, _: String)

        @EnumCaseCoding(payload: .singleValue)
        case g(value: Int)

        @EnumCaseCoding(caseKey: 8, payload: .array)
        case h(value: Int, _: String)

        @EnumCaseCoding(caseKey: "key_i", payload: .object)
        case i(value: Int, String)

        @EnumCaseCoding(payload: .object(keys: "key1", "key2"))
        case j(value: Int, _: String)

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
                    "case": "key_b",
                    "content": nil
                ]
            ),
            (
                .success(.c),
                [
                    "case": 3,
                    "content": []
                ]
            ),
            (
                .success(.d),
                [
                    "case": 4.1,
                    "content": [:]
                ]
            ),
            (
                .success(.e(value: 1)),
                [
                    "case": "e",
                    "content": 1
                ]
            ),
            (
                .success(.f(value: 2, "test")),
                [
                    "case": "f",
                    "content": [
                        "value": 2,
                        "_1": "test"
                    ]
                ]
            ),
            (
                .success(.g(value: 3)),
                [
                    "case": "g",
                    "content": 3
                ]
            ),
            (
                .success(.h(value: 4, "test2")),
                [
                    "case": 8,
                    "content": [4, "test2"]
                ]
            ),
            (
                .success(.i(value: 5, "test3")),
                [
                    "case": "key_i",
                    "content": [
                        "value": 5,
                        "_1": "test3"
                    ]
                ]
            ),
            (
                .success(.j(value: 6, "test4")),
                [
                    "case": "j",
                    "content": [
                        "key1": 6,
                        "key2": "test4"
                    ]
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
            [
                "type": "a"
            ],
            [
                "case": 1
            ],
            [
                "case": "key_b",
                "content": 1
            ],
            [
                "case": 3,
                "content": [1]
            ],
            [
                "case": 4,
                "content": []
            ],
            [
                "case": "e",
                "content": "1"
            ],
            [
                "case": "f",
                "content": [
                    "value1": 1,
                    "_1": "2"
                ]
            ],
            [
                "case": "g",
                "content": [ "value": 1 ]
            ],
            [
                "case": "h",
                "content": [ "test", 1 ]
            ],
            [
                "case": "key_i",
                "content": [ "value": 1 ]
            ],
            [
                "case": "j",
                "content": [ "key1": 1, "key": "2" ]
            ]
        ] as [JsonComponent]
    )
    func test2(_ json: JsonComponent) async throws {
        try codingTestDecodeAssert(DecodeResult<Test>.error, json)
    }

}



extension CodingTest.EnumCodableAdjacentKeyedTest {

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
                    "case": "key_b",
                    "content": nil
                ]
            ),
            (
                .c,
                [
                    "case": 3,
                    "content": []
                ]
            ),
            (
                .d,
                [
                    "case": 4.1,
                    "content": [:]
                ]
            ),
            (
                .e(value: 1),
                [
                    "case": "e",
                    "content": 1
                ]
            ),
            (
                .f(value: 2, "test"),
                [
                    "case": "f",
                    "content": [
                        "value": 2,
                        "_1": "test"
                    ]
                ]
            ),
            (
                .g(value: 3),
                [
                    "case": "g",
                    "content": 3
                ]
            ),
            (
                .h(value: 4, "test2"),
                [
                    "case": 8,
                    "content": [4, "test2"]
                ]
            ),
            (
                .i(value: 5, "test3"),
                [
                    "case": "key_i",
                    "content": [
                        "value": 5,
                        "_1": "test3"
                    ]
                ]
            ),
            (
                .j(value: 6, "test4"),
                [
                    "case": "j",
                    "content": [
                        "key1": 6,
                        "key2": "test4"
                    ]
                ]
            )
        ] as [(Test, JsonComponent)]
    )
    func test3(_ instance: Test, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }

}
