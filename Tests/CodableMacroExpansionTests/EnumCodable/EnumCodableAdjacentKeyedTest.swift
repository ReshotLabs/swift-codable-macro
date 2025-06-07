import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport

@testable import CodableMacro

#if canImport(CodableMacroMacros)
@testable import CodableMacroMacros
#endif



extension CodingExpansionTest {

    @Suite("Test EnumCodable (Adjacent Keyed)")
    final class EnumCodableAdjacentKeyedTest: CodingExpansionTest {}

}



// MARK: - Normal Cases
extension CodingExpansionTest.EnumCodableAdjacentKeyedTest {

    @EnumCodable(option: .adjucentKeyed())
    enum Test1 {
        case a, b
    }


    @Test("Auto Type/Payload Key | No Associated Values | Auto Case Key | Auto Payload")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                case a, b
            }
            """, 
            expandedSource: """
            enum Test {
                case a, b
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            self = .a
                            return
                        case "b":
                            self = .b
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode("a", forKey: .ktype)
                    case .b:
                        try container.encode("b", forKey: .ktype)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test2 {
        @EnumCaseCoding(key: "key_a")
        case a
    }


    @Test("Auto Type/Payload Key | No Associated Values | String Case Key | Auto Payload")
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(key: "key_a")
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "key_a":
                            self = .a
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode("key_a", forKey: .ktype)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test3 {
        @EnumCaseCoding(key: 1)
        case a
    }


    @Test("Auto Type/Payload Key | No Associated Values | Int Case Key | Auto Payload")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(key: 1)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(Double.self, forKey: .ktype) {
                        switch type {
                        case 1:
                            self = .a
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode(1, forKey: .ktype)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test4 {
        @EnumCaseCoding(key: 1.1)
        case a
    }


    @Test("Auto Type/Payload Key | No Associated Values | Float Case Key | Auto Payload")
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(key: 1.1)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(Double.self, forKey: .ktype) {
                        switch type {
                        case 1.1:
                            self = .a
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode(1.1, forKey: .ktype)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test5 {
        @EnumCaseCoding(emptyPayloadOption: .nothing)
        case a
    }


    @Test("Auto Type/Payload Key | No Associated Values | Auto Case Key | No Payload")
    func test5() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .nothing)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            self = .a
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode("a", forKey: .ktype)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test6 {
        @EnumCaseCoding(emptyPayloadOption: .null)
        case a
    }


    @Test("Auto Type/Payload Key | No Associated Values | Auto Case Key | Null Payload")
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .null)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            if try container.decodeNil(forKey: .kpayload) {
                                self = .a
                                return
                            }
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode("a", forKey: .ktype)
                        try container.encodeNil(forKey: .kpayload)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test7 {
        @EnumCaseCoding(emptyPayloadOption: .emptyArray)
        case a
    }


    @Test("Auto Type/Payload Key | No Associated Values | Auto Case Key | Empty Array Payload")
    func test7() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .emptyArray)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let nestedContainer = try container.nestedUnkeyedContainer(forKey: .kpayload)
                            if nestedContainer.count == 0 {
                                self = .a
                                return
                            }
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode("a", forKey: .ktype)
                        try container.encode([DummyDecodableType](), forKey: .kpayload)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test8 {
        @EnumCaseCoding(emptyPayloadOption: .emptyObject)
        case a
    }


    @Test("Auto Type/Payload Key | No Associated Values | Auto Case Key | Empty Object Payload")
    func test8() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .emptyObject)
                case a
            }
            """, 
            expandedSource: #"""
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                private struct $__unconditional_coding_keys: CodingKey {
                    init?(stringValue: String) {
                        self.stringValue = stringValue
                    }
                    init?(intValue: Int) {
                        self.intValue = intValue
                        self.stringValue = "\(intValue)"
                    }
                    var intValue: Int?
                    var stringValue: String
                }
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let nestedContainer = try container.nestedContainer(keyedBy: $__unconditional_coding_keys.self, forKey: .kpayload)
                            if nestedContainer.allKeys.isEmpty {
                                self = .a
                                return
                            }
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case .a:
                        try container.encode("a", forKey: .ktype)
                        try container.encode(DummyDecodableType(), forKey: .kpayload)
                    }
                }
            }
            """#
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test9 {
        case a(value: Int)
    }


    @Test("Auto Type/Payload Key | Single Associated Value | Auto Case Key | Auto Payload")
    func test9() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                case a(value: Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let value = try container.decode(Int.self, forKey: .kpayload)
                            self = .a(value: value)
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case let .a(value0):
                        try container.encode("a", forKey: .ktype)
                        try container.encode(value0, forKey: .kpayload)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test10 {
        case a(value: Int, _: String)
    }


    @Test("Auto Type/Payload Key | Multi Associated Values | Auto Case Key | Auto Payload")
    func test10() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                enum $__coding_keys_root_a: String, CodingKey {
                    case kvalue = "value"
                    case k_1 = "_1"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kpayload)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kvalue)
                            let value1 = try nestedContainer.decode(String.self, forKey: .k_1)
                            self = .a(value: value0, value1)
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case let .a(value0, value1):
                        try container.encode("a", forKey: .ktype)
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kpayload)
                        try nestedContainer.encode(value0, forKey: .kvalue)
                        try nestedContainer.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test11 {
        @EnumCaseCoding(payload: .singleValue)
        case a(value: Int)
    }


    @Test("Auto Type/Payload Key | Single Associated Value | Auto Case Key | Single Value Payload")
    func test11() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(payload: .singleValue)
                case a(value: Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let value = try container.decode(Int.self, forKey: .kpayload)
                            self = .a(value: value)
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case let .a(value0):
                        try container.encode("a", forKey: .ktype)
                        try container.encode(value0, forKey: .kpayload)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test12 {
        @EnumCaseCoding(payload: .array)
        case a(value: Int, _: String)
    }


    @Test("Auto Type/Payload Key | Multi Associated Values | Auto Case Key | Array Payload")
    func test12() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(payload: .array)
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .kpayload)
                            let value0 = try nestedContainer.decode(Int.self)
                            let value1 = try nestedContainer.decode(String.self)
                            self = .a(value: value0, value1)
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case let .a(value0, value1):
                        try container.encode("a", forKey: .ktype)
                        var nestedContainer = container.nestedUnkeyedContainer(forKey: .kpayload)
                        try nestedContainer.encode(value0)
                        try nestedContainer.encode(value1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test13 {
        @EnumCaseCoding(payload: .object)
        case a(value: Int, _: String)
    }


    @Test("Auto Type/Payload Key | Multi Associated Values | Auto Case Key | Object Payload")
    func test13() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(payload: .object)
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                enum $__coding_keys_root_a: String, CodingKey {
                    case kvalue = "value"
                    case k_1 = "_1"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kpayload)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kvalue)
                            let value1 = try nestedContainer.decode(String.self, forKey: .k_1)
                            self = .a(value: value0, value1)
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case let .a(value0, value1):
                        try container.encode("a", forKey: .ktype)
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kpayload)
                        try nestedContainer.encode(value0, forKey: .kvalue)
                        try nestedContainer.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed())
    enum Test14 {
        @EnumCaseCoding(payload: .object(keys: "key1", "key2"))
        case a(value: Int, _: String)
    }


    @Test("Auto Type/Payload Key | Multi Associated Values | Auto Case Key | Custom Object Payload")
    func test14() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(payload: .object(keys: "key1", "key2"))
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case ktype = "type", kpayload = "payload"
                }
                enum $__coding_keys_root_a: String, CodingKey {
                    case kkey1 = "key1"
                    case kkey2 = "key2"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kpayload)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kkey1)
                            let value1 = try nestedContainer.decode(String.self, forKey: .kkey2)
                            self = .a(value: value0, value1)
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case let .a(value0, value1):
                        try container.encode("a", forKey: .ktype)
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kpayload)
                        try nestedContainer.encode(value0, forKey: .kkey1)
                        try nestedContainer.encode(value1, forKey: .kkey2)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .adjucentKeyed(typeKey: "case", payloadKey: "content"))
    enum Test15 {
        @EnumCaseCoding(payload: .object)
        case a(value: Int, _: String)
    }


    @Test("Custom Type/Payload Key | Multi Associated Values | Auto Case Key | Object Payload")
    func test15() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed(typeKey: "case", payloadKey: "content"))
            enum Test {
                @EnumCaseCoding(payload: .object)
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case kcase = "case", kcontent = "content"
                }
                enum $__coding_keys_root_a: String, CodingKey {
                    case kvalue = "value"
                    case k_1 = "_1"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .kcase) {
                        switch type {
                        case "a":
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kcontent)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kvalue)
                            let value1 = try nestedContainer.decode(String.self, forKey: .k_1)
                            self = .a(value: value0, value1)
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .value(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: $__coding_keys_root.self)
                    switch self {
                    case let .a(value0, value1):
                        try container.encode("a", forKey: .kcase)
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .kcontent)
                        try nestedContainer.encode(value0, forKey: .kvalue)
                        try nestedContainer.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }

}


// MARK: - Error Cases
extension CodingExpansionTest.EnumCodableAdjacentKeyedTest {

    // @EnumCodable(option: .adjucentKeyed(typeKey: "payload"))
    // enum TestE1 {
    //     case a
    // }


    @Test("Conflict Type Key & Payload Key")
    func testE1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed(typeKey: "payload"))
            enum TestE1 {
                case a
            }
            """, 
            expandedSource: """
            enum TestE1 {
                case a
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.conflictedTypeAndPayloadKeys(), 
                    line: 1, 
                    column: 1
                )
            ]
        )
    }


    // @EnumCodable(option: .adjucentKeyed())
    // enum TestE2 {
    //     @EnumCaseCoding(key: 10.0)
    //     case a
    //     @EnumCaseCoding(key: 10)
    //     case b
    //     @EnumCaseCoding(key: 0x0A)
    //     case c
    // }


    @Test("Conflict Case Keys", .disabled("Currently no way to control the order of dianostics"))
    func testE2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(key: 10.0)
                case a
                @EnumCaseCoding(key: 10)
                case b
                @EnumCaseCoding(key: 0x0A)
                case c
            }
            """, 
            expandedSource: """
            enum Test {
                case a
                case b
                case c
            }
            """,
            diagnostics: [
                .init(message: .codingMacro.enumCodable.duplicatedCaseKey(with: ["b", "c"]), line: 3, column: 26),
                .init(message: .codingMacro.enumCodable.duplicatedCaseKey(with: ["a", "b"]), line: 7, column: 26),
                .init(message: .codingMacro.enumCodable.duplicatedCaseKey(with: ["a", "c"]), line: 5, column: 26),
            ]
        )
    }


    // @EnumCodable(option: .adjucentKeyed())
    // enum TestE3 {
    //     @EnumCaseCoding(unkeyedRawValuePayload: 1)
    //     case a
    // }


    @Test("Unkeyed Setting")
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .adjucentKeyed())
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: 1)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(.adjucentKeyed()), 
                    line: 3, 
                    column: 21
                )
            ]
        )
    }

}