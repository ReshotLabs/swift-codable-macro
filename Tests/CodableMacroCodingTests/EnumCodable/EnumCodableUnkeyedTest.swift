import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {

    @Suite("Test EnumCodable (Unkeyed) in Actual Coding")
    final class EnumCodableUnkeyedTest: CodingTest {}

}


struct UnconditionalCodingKey: CodingKey {
    var intValue: Int?
    var stringValue: String
    init(intValue: Int? = nil, stringValue: String) {
        self.intValue = intValue
        self.stringValue = stringValue
    }
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
    }
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
}



extension CodingTest.EnumCodableUnkeyedTest {

    struct IntExpresssible: ExpressibleByIntegerLiteral, Equatable, Codable {
        let value: Int
        init(integerLiteral value: Int) {
            self.value = value
        }
        enum CodingKeys: String, CodingKey {
            case value = "value"
        }
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.value = try container.decode(Int.self, forKey: .value)
        }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)
        }
    }

    struct StringExpresssible: ExpressibleByStringLiteral, Equatable, Codable {
        let value: String
        init(stringLiteral value: String) {
            self.value = value
        }
        enum CodingKeys: String, CodingKey {
            case value = "value"
        }
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.value = try container.decode(String.self, forKey: .value)
        }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)
        }
    }

    struct FloatExpresssible: ExpressibleByFloatLiteral, Equatable, Codable {
        let value: Double
        init(floatLiteral value: Double) {
            self.value = value
        }
        enum CodingKeys: String, CodingKey {
            case value = "value"
        }
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.value = try container.decode(Double.self, forKey: .value)
        }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)
        }
    }

    @EnumCodable(option: .unkeyed)
    enum Test: Equatable {

        case a 

        @EnumCaseCoding(unkeyedRawValuePayload: "bb")
        case b

        @EnumCaseCoding(unkeyedRawValuePayload: 3)
        case c

        @EnumCaseCoding(unkeyedRawValuePayload: 4.1)
        case d

        @EnumCaseCoding(unkeyedRawValuePayload: 5, type: CodingTest.EnumCodableUnkeyedTest.IntExpresssible.self)
        case e

        @EnumCaseCoding(unkeyedRawValuePayload: 6.1, type: CodingTest.EnumCodableUnkeyedTest.FloatExpresssible.self)
        case f

        @EnumCaseCoding(unkeyedRawValuePayload: "gg", type: CodingTest.EnumCodableUnkeyedTest.StringExpresssible.self)
        case g

        case h(value: Int)

        case i(value: Int, _: String)

        @EnumCaseCoding(unkeyedPayload: .array)
        case j(value: Int, _: String)

        @EnumCaseCoding(unkeyedPayload: .object)
        case k(valueK: String, _: String)

        @EnumCaseCoding(unkeyedPayload: .object(keys: "key1", "key2"))
        case l(value: Int, _: String)

        @EnumCaseCoding(unkeyedPayload: .object(keys: "0", "1"))
        case m(value: Int, _: String)

    }


    @Test(
        "Test Decoding (success)",
        arguments: [
//           (
//               .success(.a),
//               "a"
//           ),
//           (
//               .success(.b),
//               "bb"
//           ),
//           (
//               .success(.c),
//               3
//           ),
//           (
//               .success(.d),
//               4.1
//           ),
//            (
//                .success(.e),
//                ["value": 5]
//            ),
//            (
//                .success(.f),
//                ["value": 6.1]
//            ),
//            (
//                .success(.g),
//                ["value": "gg"]
//            ),
//            (
//                .success(.h(value: 7)),
//                7
//            ),
//            (
//                .success(.i(value: 8, "ii")),
//                [
//                    "value": 8,
//                    "_1": "ii"
//                ]
//            ),
            (
                .success(.j(value: 9, "jj")),
                [9, "jj"]
            ),
//            (
//                .success(.k(valueK: "kk1", "kk2")),
//                ["valueK": "kk1", "_1": "kk2"]
//            ),
//            (
//                .success(.l(value: 11, "ll")),
//                ["key1": 11, "key2": "ll"]
//            )
        ] as [(DecodeResult<Test>, JsonComponent)]
    )
    func test1(_ expectedInstance: DecodeResult<Test>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }


    @Test(
        "Test Decoding (failure)",
        arguments: [
            "aa",
            nil,
            3.1,
            ["value": "5"],
            ["value1": 5],
            ["value": "ggg"],
            ["value": 7, "_0": "ii"],
            ["jj", 8],
            ["kk1", "kk2"],
            ["key1": 11, "key2": [:]]
        ] as [JsonComponent]
    )
    func test2(_ json: JsonComponent) async throws {
        try codingTestDecodeAssert(DecodeResult<Test>.error, json)
    }

}



extension CodingTest.EnumCodableUnkeyedTest {

    @Test(
        "Test Encoding",
        arguments: [
            (
                .a, 
                "a"
            ),
            (
                .b, 
                "bb"
            ),
            (
                .c, 3
            ),
            (
                .d, 
                4.1
            ),
            (
                .e, 
                ["value": 5]
            ),
            (
                .f, 
                ["value": 6.1]
            ),
            (
                .g, 
                ["value": "gg"]
            ),
            (
                .h(value: 7), 
                7
            ),
            (
                .i(value: 8, "ii"), 
                ["value": 8, "_1": "ii"]
            ),
            (
                .j(value: 9, "jj"), 
                [9, "jj"]
            ),
            (
                .k(valueK: "kk1", "kk2"), 
                ["valueK": "kk1", "_1": "kk2"]
            ),
            (
                .l(value: 11, "ll"), 
                ["key1": 11, "key2": "ll"]
            )
        ] as [(Test, JsonComponent)]
    )
    func test3(_ instance: Test, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }

}
