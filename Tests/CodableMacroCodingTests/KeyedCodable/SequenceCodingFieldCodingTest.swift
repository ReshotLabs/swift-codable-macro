import Testing
@testable import CodableMacro
import Foundation



extension CodingTest {

    @Suite("Test SequenceCodingField in Actual Coding", .tags(.coding.keyedCoding))
    class SequenceCodingFieldCodingTest: CodingTest {}

}


extension CodingTest.SequenceCodingFieldCodingTest {

    @Codable
    struct SomeType1: Equatable {

        @CodingField("path1", "a")
        var a: [Int]

        @CodingField("path1", "b")
        @SequenceCodingField(subPath: "inner", "element", elementEncodedType: Int.self, decodeTransform: Set.init(_:))
        var b: Set<Int>

        @SequenceCodingField(
            subPath: "element",
            elementEncodedType: Int.self, 
            onMissing: .ignore,
            onMismatch: .value(-1),
            decodeTransform: { Dictionary(zip($0, $0.map(\.description)), uniquingKeysWith: { $1 }) }, 
            encodeTransform: { $0.keys }
        )
        var c: [Int:String]

        @SequenceCodingField(
            elementEncodedType: Int.self, 
            onMissing: .value(-1)
        )
        var d: [Int]

        @SequenceCodingField(
            elementEncodedType: Int.self, 
            onMismatch: .value(-1)
        )
        var e: [Int]

    }


    @Test(
        "Test Decoding",
        arguments: [
            (
                1,
                .success(.init(a: [1, 2], b: [1, 2], c: [1: "1", 2: "2", -1: "-1"], d: [1, -1, 2], e: [1, -1, 2])),
                [
                    "path1": [
                        "a": [1, 2],
                        "b": [
                            ["inner": ["element": 1]],
                            ["inner": ["element": 2]],
                        ]
                    ],
                    "c": [
                        ["element": 1],
                        ["element": 2],
                        ["element": nil],       // Missing
                        ["element1": 4],        // Missing
                        ["element": "5"],       // Mismatch
                        [1, 2]                  // Mismatch
                    ],
                    "d": [1, nil, 2],
                    "e": [1, "2", 2]
                ]
            ),
            (
                2,
                .error,
                [
                    "path1": [
                        "a": [1, 2, "3"],
                        "b": [
                            ["inner": ["element": 1]],
                            ["inner": ["element": 2]],
                        ]
                    ],
                    "c": [
                        ["element": 1],
                        ["element": 2],
                        ["element": nil],        // Missing
                        ["element1": 4],         // Missing
                        ["element1": "5"],       // Mismatch
                        [1, 2]                  // Mismatch
                    ],
                    "d": [1, nil, 2],
                    "e": [1, "2", 2]
                ]
            ),
            (
                3,
                .error,
                [
                    "path1": [
                        "a": [1, 2],
                        "b": [
                            ["inner": ["element": 1]],
                            ["inner": ["element": 2]],
                            ["inner": ["element1": 3]],
                        ]
                    ],
                    "c": [
                        ["element": 1],
                        ["element": 2],
                        ["element": nil],       // Missing
                        ["element1": 4],        // Missing
                        ["element": "5"],       // Mismatch
                        [1, 2]                  // Mismatch
                    ],
                    "d": [1, nil, 2],
                    "e": [1, "2", 2]
                ]
            ),
            (
                4,
                .error,
                [
                    "path1": [
                        "a": [1, 2],
                        "b": [
                            ["inner": ["element": 1]],
                            ["inner": ["element": 2]],
                        ]
                    ],
                    "c": [
                        ["element": 1],
                        ["element": 2],
                        ["element": nil],       // Missing
                        ["element1": 4],        // Missing
                        ["element": "5"],       // Mismatch
                        [1, 2]                  // Mismatch
                    ],
                    "d": [1, "3", 2],
                    "e": [1, "2", 2]
                ]
            ),
            (
                5,
                .error,
                [
                    "path1": [
                        "a": [1, 2],
                        "b": [
                            ["inner": ["element": 1]],
                            ["inner": ["element": 2]],
                        ]
                    ],
                    "c": [
                        ["element": 1],
                        ["element": 2],
                        ["element": nil],       // Missing
                        ["element1": 4],        // Missing
                        ["element": "5"],       // Mismatch
                        [1, 2]                  // Mismatch
                    ],
                    "d": [1, nil, 2],
                    "e": [1, nil, 2]
                ]
            ),
        ] as [(Int, DecodeResult<SomeType1>, JsonComponent)]
    )
    func testDecode(_ _: Int, _ expectedInstance: DecodeResult<SomeType1>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }


    @Test(
        "Test Encoding",
        arguments: [
            (
                1,
                .init(a: [1, 2], b: [1, 2], c: [1: "1", 2: "2"], d: [1, 2], e: [1, 2]),
                [
                    "path1": [
                        "a": [1, 2],
                        "b": [
                            ["inner": ["element": 1]],
                            ["inner": ["element": 2]],
                        ]
                    ],
                    "c": [
                        ["element": 1],
                        ["element": 2]
                    ],
                    "d": [1, 2],
                    "e": [1, 2]
                ]
            )
        ] as [(Int, SomeType1, JsonComponent)]
    )
    func testEncode(_ _: Int, _ instance: SomeType1, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }

}
