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

    @Suite("Test EnumCodable (Unkeyed)")
    final class EnumCodableUnkeyedTest: CodingExpansionTest {}

}



extension CodingExpansionTest.EnumCodableUnkeyedTest {

    @EnumCodable(option: .unkeyed)
    enum Test1 {
        case a, b
    }


    @Test("No Associated Values | Auto Payload")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                case a, b
            }
            """, 
            expandedSource: """
            enum Test {
                case a, b
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(String.self) {
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode("a" as String)
                    case .b:
                        var container = encoder.singleValueContainer()
                        try container.encode("b" as String)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test2 {
        @EnumCaseCoding(unkeyedRawValuePayload: 1)
        case a
    }


    @Test("No Associated Values | Int Payload")
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: 1)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(Int.self) {
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode(1 as Int)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test3 {
        @EnumCaseCoding(unkeyedRawValuePayload: "a")
        case a
    }


    @Test("No Associated Values | String Payload")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: "a")
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(String.self) {
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode("a" as String)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test4 {
        @EnumCaseCoding(unkeyedRawValuePayload: 1.1)
        case a
    }


    @Test("No Associated Values | Float Payload")
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: 1.1)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(Double.self) {
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode(1.1 as Double)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test5 {
        @EnumCaseCoding(unkeyedRawValuePayload: 0x1, type: CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self)
        case a
    }


    @Test("No Associated Values | Custom Int Payload")
    func test5() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: 0x1, type: CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self) {
                        case 0x1:
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode(0x1 as CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test6 {
        @EnumCaseCoding(unkeyedRawValuePayload: 1.1, type: CodingExpansionTest.EnumCodableUnkeyedTest.FloatExpressible.self)
        case a
    }


    @Test("No Associated Values | Custom Float Payload")
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: 1.1, type: CodingExpansionTest.EnumCodableUnkeyedTest.FloatExpressible.self)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(CodingExpansionTest.EnumCodableUnkeyedTest.FloatExpressible.self) {
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode(1.1 as CodingExpansionTest.EnumCodableUnkeyedTest.FloatExpressible)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test7 {
        @EnumCaseCoding(unkeyedRawValuePayload: "1.1", type: CodingExpansionTest.EnumCodableUnkeyedTest.StringExpressible.self)
        case a
    }


    @Test("No Associated Values | Custom String Payload")
    func test7() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: "1.1", type: CodingExpansionTest.EnumCodableUnkeyedTest.StringExpressible.self)
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(CodingExpansionTest.EnumCodableUnkeyedTest.StringExpressible.self) {
                        case "1.1":
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode("1.1" as CodingExpansionTest.EnumCodableUnkeyedTest.StringExpressible)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test8 {
        case a(value: Int)
    }


    @Test("Single Associated Value | Auto Payload")
    func test8() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                case a(value: Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int)
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        if let value = try? container.decode(Int.self) {
                            self = .a(value: value)
                            return
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
                    switch self {
                    case let .a(value):
                        var container = encoder.singleValueContainer()
                        try container.encode(value)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test9 {
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Auto Payload")
    func test9() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
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
                    case k_1 = "_1", kvalue = "value"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        do {
                            let value0 = try container.decode(Int.self, forKey: .kvalue)
                            let value1 = try container.decode(String.self, forKey: .k_1)
                            self = .a(value: value0, value1)
                            return
                        } catch {
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
                    switch self {
                    case let .a(value0, value1):
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(value0, forKey: .kvalue)
                        try container.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test10 {
        @EnumCaseCoding(unkeyedPayload: .singleValue)
        case a(value: Int)
    }


    @Test("Single Associated Value | Single Value Payload")
    func test10() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedPayload: .singleValue)
                case a(value: Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int)
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        if let value = try? container.decode(Int.self) {
                            self = .a(value: value)
                            return
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
                    switch self {
                    case let .a(value):
                        var container = encoder.singleValueContainer()
                        try container.encode(value)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test11 {
        @EnumCaseCoding(unkeyedPayload: .array)
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Array Payload")
    func test11() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedPayload: .array)
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if var container = try? decoder.unkeyedContainer() {
                        do {
                            let value0 = try container.decode(Int.self)
                            let value1 = try container.decode(String.self)
                            self = .a(value: value0, value1)
                            return
                        } catch {
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
                    switch self {
                    case let .a(value0, value1):
                        var container = encoder.unkeyedContainer()
                        try container.encode(value0)
                        try container.encode(value1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test12 {
        @EnumCaseCoding(unkeyedPayload: .object)
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Object Payload")
    func test12() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedPayload: .object)
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case k_1 = "_1", kvalue = "value"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        do {
                            let value0 = try container.decode(Int.self, forKey: .kvalue)
                            let value1 = try container.decode(String.self, forKey: .k_1)
                            self = .a(value: value0, value1)
                            return
                        } catch {
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
                    switch self {
                    case let .a(value0, value1):
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(value0, forKey: .kvalue)
                        try container.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test13 {
        @EnumCaseCoding(unkeyedPayload: .object(keys: "key1", "key2"))
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Custom Object Payload")
    func test13() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedPayload: .object(keys: "key1", "key2"))
                case a(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case kkey1 = "key1", kkey2 = "key2"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        do {
                            let value0 = try container.decode(Int.self, forKey: .kkey1)
                            let value1 = try container.decode(String.self, forKey: .kkey2)
                            self = .a(value: value0, value1)
                            return
                        } catch {
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
                    switch self {
                    case let .a(value0, value1):
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(value0, forKey: .kkey1)
                        try container.encode(value1, forKey: .kkey2)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test14: Int {
        case a
        case b = 4
        case c
    }


    @Test("No Associated Values | Native Int Payload")
    func test14() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test: Int {
                case a
                case b = 4
                case c
            }
            """, 
            expandedSource: """
            enum Test: Int {
                case a
                case b = 4
                case c
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(Int.self) {
                        case 0:
                            self = .a
                            return
                        case 4:
                            self = .b
                            return
                        case 5:
                            self = .c
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode(0 as Int)
                    case .b:
                        var container = encoder.singleValueContainer()
                        try container.encode(4 as Int)
                    case .c:
                        var container = encoder.singleValueContainer()
                        try container.encode(5 as Int)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test15: String {
        case a
        @EnumCaseCoding(unkeyedRawValuePayload: 1.1)
        case b
        case c = "cc"
        @EnumCaseCoding(unkeyedRawValuePayload: 0x1, type: CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self)
        case d
    }


    @Test("No Associated Values | Mixed Payload")
    func test15() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test: String {
                case a
                @EnumCaseCoding(unkeyedRawValuePayload: 1.1)
                case b
                case c = "cc"
                @EnumCaseCoding(unkeyedRawValuePayload: 0x1, type: CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self)
                case d
            }
            """, 
            expandedSource: """
            enum Test: String {
                case a
                case b
                case c = "cc"
                case d
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self) {
                        case 0x1:
                            self = .d
                            return
                        default:
                            break
                        }
                        switch try? container.decode(Double.self) {
                        case 1.1:
                            self = .b
                            return
                        default:
                            break
                        }
                        switch try? container.decode(String.self) {
                        case "a":
                            self = .a
                            return
                        case "cc":
                            self = .c
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode("a" as String)
                    case .b:
                        var container = encoder.singleValueContainer()
                        try container.encode(1.1 as Double)
                    case .c:
                        var container = encoder.singleValueContainer()
                        try container.encode("cc" as String)
                    case .d:
                        var container = encoder.singleValueContainer()
                        try container.encode(0x1 as CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .unkeyed)
    enum Test16 {
        case a
        @EnumCaseCoding(unkeyedRawValuePayload: 0x1, type: CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self)
        case b
        @EnumCaseCoding(unkeyedPayload: .singleValue)
        case c(value: String)
        @EnumCaseCoding(unkeyedPayload: .object)
        case d(value: Int, _: String)
    }


    @Test("Mixed Associated Values | Mixed Payload")
    func test16() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                case a
                @EnumCaseCoding(unkeyedRawValuePayload: 0x1, type: CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self)
                case b
                @EnumCaseCoding(unkeyedPayload: .singleValue)
                case c(value: String)
                @EnumCaseCoding(unkeyedPayload: .object)
                case d(value: Int, _: String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a
                case b
                case c(value: String)
                case d(value: Int, _: String)
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case k_1 = "_1", kvalue = "value"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.singleValueContainer() {
                        switch try? container.decode(CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible.self) {
                        case 0x1:
                            self = .b
                            return
                        default:
                            break
                        }
                        switch try? container.decode(String.self) {
                        case "a":
                            self = .a
                            return
                        default:
                            break
                        }
                        if let value = try? container.decode(String.self) {
                            self = .c(value: value)
                            return
                        }
                    }
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        do {
                            let value0 = try container.decode(Int.self, forKey: .kvalue)
                            let value1 = try container.decode(String.self, forKey: .k_1)
                            self = .d(value: value0, value1)
                            return
                        } catch {
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
                    switch self {
                    case .a:
                        var container = encoder.singleValueContainer()
                        try container.encode("a" as String)
                    case .b:
                        var container = encoder.singleValueContainer()
                        try container.encode(0x1 as CodingExpansionTest.EnumCodableUnkeyedTest.IntExpressible)
                    case let .c(value):
                        var container = encoder.singleValueContainer()
                        try container.encode(value)
                    case let .d(value0, value1):
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(value0, forKey: .kvalue)
                        try container.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    struct StringExpressible: ExpressibleByStringLiteral, Sendable, Codable, Equatable {
        init(stringLiteral value: String) {}
    }

    struct IntExpressible: ExpressibleByIntegerLiteral, Sendable, Codable, Equatable {
        init(integerLiteral value: Int) {}
    }

    struct FloatExpressible: ExpressibleByFloatLiteral, Sendable, Codable, Equatable {
        init(floatLiteral value: Double) {}
    }

}



extension CodingExpansionTest.EnumCodableUnkeyedTest {

    // @EnumCodable(option: .unkeyed)
    // enum TestE1 {
    //     @EnumCaseCoding(key: "test")
    //     case a
    // }


    @Test("Keyed Setting 1")
    func testE1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(key: "test")
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
                    message: .codingMacro.enumCodable.keyedSettingInUnkeyedEnumCoding(), 
                    line: 3, 
                    column: 21
                )
            ]
        )
    }


    // @EnumCodable(option: .unkeyed)
    // enum TestE2 {
    //     @EnumCaseCoding(emptyPayloadOption: .null)
    //     case a
    // }


    @Test("Keyed Setting 2")
    func testE2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .null)
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
                    message: .codingMacro.enumCodable.keyedSettingInUnkeyedEnumCoding(), 
                    line: 3, 
                    column: 21
                )
            ]
        )
    }


    // @EnumCodable(option: .unkeyed)
    // enum TestE3 {
    //     @EnumCaseCoding(payload: .object)
    //     case a(String)
    // }


    @Test("Keyed Setting 3")
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(payload: .object)
                case a(String)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(String)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.keyedSettingInUnkeyedEnumCoding(), 
                    line: 3, 
                    column: 21
                )
            ]
        )
    }


    // @EnumCodable(option: .unkeyed)
    // enum TestE4 {
    //     @EnumCaseCoding(unkeyedRawValuePayload: Int.zero)
    //     case a
    // }


    @Test("Not Literal Payload Value")
    func testE4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: Int.zero)
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
                    message: .syntaxInfo.literalValue.notLiteral(), 
                    line: 3, 
                    column: 45
                )
            ]
        )
    }


    // @EnumCodable(option: .unkeyed)
    // enum TestE5 {
    //     @EnumCaseCoding(unkeyedRawValuePayload: "b")
    //     case a
    //     case b
    // }


    @Test("Conflict Raw Value Payload 1", .disabled("Currently no way to control the order of dianostics"))
    func testE5() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: "b")
                case a
                case b
            }
            """, 
            expandedSource: """
            enum Test {
                case a
                case b
            }
            """,
            diagnostics: [
                .init(message: .codingMacro.enumCodable.duplicatedUnkeyedRawValuePayload(with: ["b"]), line: 3, column: 46),
                .init(message: .codingMacro.enumCodable.duplicatedUnkeyedRawValuePayload(with: ["a"]), line: 5, column: 10)
            ]
        )
    }


    
    // @EnumCodable(option: .unkeyed)
    // enum TestE6: Int {
    //     case a = 1
    //     @EnumCaseCoding(unkeyedRawValuePayload: 0x1)
    //     case b
    // }


    @Test("Conflict Raw Value Payload 2", .disabled("Currently no way to control the order of dianostics"))
    func testE6() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .unkeyed)
            enum Test: Int {
                case a = 1
                @EnumCaseCoding(unkeyedRawValuePayload: 0x1)
                case b
            }
            """, 
            expandedSource: """
            enum Test: Int {
                case a = 1
                @EnumCaseCoding(unkeyedRawValuePayload: 0x1)
                case b
            }
            """,
            diagnostics: [
                .init(message: .codingMacro.enumCodable.duplicatedUnkeyedRawValuePayload(with: ["b"]), line: 3, column: 14),
                .init(message: .codingMacro.enumCodable.duplicatedUnkeyedRawValuePayload(with: ["a"]), line: 5, column: 46)
            ]
        )
    }

}