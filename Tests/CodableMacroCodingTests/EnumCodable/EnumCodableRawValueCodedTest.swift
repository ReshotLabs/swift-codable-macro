import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {

    @Suite("Test EnumCodable (Raw Value Coded) in Actual Coding")
    final class EnumCodableRawValueCodedTest: CodingTest {}

}



extension CodingTest.EnumCodableRawValueCodedTest {

    struct FloatExpresssible: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, Equatable, RawRepresentable, Codable {
        let value: Double
        var rawValue: Double { value }
        init(floatLiteral value: Double) {
            self.value = value
        }
        init(integerLiteral value: Int) {
            self.value = Double(value)
        }
        init(rawValue: Double) {
            self.value = rawValue
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

    @EnumCodable(option: .rawValueCoded)
    enum Test1: Int, Equatable {
        case a
        case b = 4
        case c
    }

    @EnumCodable(option: .rawValueCoded)
    enum Test2: FloatExpresssible, Equatable {
        case a
        case b = 4
        case c
        case d = 6.5
    }


    @Test(
        "Test Decoding 1 (success)",
        arguments: [
            (.success(.a), 0),
            (.success(.b), 4),
            (.success(.c), 5)
        ] as [(DecodeResult<Test1>, JsonComponent)]
    )
    func test1(_ expectedInstance: DecodeResult<Test1>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }


    @Test(
        "Test Decoding 1 (failure)",
        arguments: [
            "4",
            [4],
            ["value": 4],
            [:],
            10
        ] as [JsonComponent]
    )
    func test2(_ json: JsonComponent) async throws {
        try codingTestDecodeAssert(DecodeResult<Test1>.error, json)
    }


    @Test(
        "Test Decoding 2 (success)",
        arguments: [
            (
                .success(.a), 
                ["value": 0]
            ),
            (
                .success(.b),
                ["value": 4]
            ),
            (
                .success(.c),
                ["value": 5]
            ),
            (
                .success(.d), 
                ["value": 6.5]
            )
        ] as [(DecodeResult<Test2>, JsonComponent)]
    )
    func test3(_ expectedInstance: DecodeResult<Test2>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }


    @Test(
        "Test Decoding 2 (failure)",
        arguments: [
            4,
            "4",
            [4],
            [:],
            ["value": "4"],
            ["value1": 4],
            ["value": 10],
            ["value": [4]],
            ["value": ["value": 4]],
            ["value": nil],
            ["value": [:]],
        ] as [JsonComponent]
    )
    func test4(_ json: JsonComponent) async throws {
        try codingTestDecodeAssert(DecodeResult<Test2>.error, json)
    }

}



extension CodingTest.EnumCodableRawValueCodedTest {

    @Test(
        "Test Encoding 1",
        arguments: [
            (.a, 0),
            (.b, 4),
            (.c, 5)
        ] as [(Test1, JsonComponent)]
    )
    func test1(_ expectedInstance: Test1, _ json: JsonComponent) async throws {
        try codingTestEncodeAssert(expectedInstance, json)
    }


    @Test(
        "Test Encoding 2",
        arguments: [
            (.a, ["value": 0]),
            (.b, ["value": 4]),
            (.c, ["value": 5]),
            (.d, ["value": 6.5])
        ] as [(Test2, JsonComponent)]
    )
    func test2(_ expectedInstance: Test2, _ json: JsonComponent) async throws {
        try codingTestEncodeAssert(expectedInstance, json)
    }

}