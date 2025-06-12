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

    @Suite("Test EnumCodable (External Keyed)")
    final class EnumCodableExternalKeyedTest: CodingExpansionTest {}

}



extension CodingExpansionTest.EnumCodableExternalKeyedTest {

    @EnumCodable
    enum Test1 {
        case a, b
    }


    @Test("No Associated Values | Auto Case Key | Auto Payload")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                    case kb = "b"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            if try container.decodeNil(forKey: .ka) {
                                self = .a
                                return
                            }
                        case .kb:
                            if try container.decodeNil(forKey: .kb) {
                                self = .b
                                return
                            }
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case .a:
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encodeNil(forKey: .ka)
                    case .b:
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encodeNil(forKey: .kb)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test2 {
        @EnumCaseCoding(caseKey: "key_a")
        case a
    }


    @Test("No Associated Values | Custom Case Key | Auto Payload")
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(caseKey: "key_a")
                case a
            }
            """, 
            expandedSource: """
            enum Test {
                case a
            }

            extension Test: EnumCodableProtocol {
                enum $__coding_keys_root: String, CodingKey {
                    case kkey_a = "key_a"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .kkey_a:
                            if try container.decodeNil(forKey: .kkey_a) {
                                self = .a
                                return
                            }
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case .a:
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encodeNil(forKey: .kkey_a)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test3 {
        @EnumCaseCoding(emptyPayloadOption: .null)
        case a
    }


    @Test("No Associated Values | Auto Case Key | Null Payload")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            if try container.decodeNil(forKey: .ka) {
                                self = .a
                                return
                            }
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case .a:
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encodeNil(forKey: .ka)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test4 {
        @EnumCaseCoding(emptyPayloadOption: .nothing)
        case a
    }


    @Test("No Associated Values | Auto Case Key | No Payload")
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                public init(from decoder: Decoder) throws {
                    if let caseKey = try? decoder.singleValueContainer().decode(String.self) {
                        switch caseKey {
                        case "a":
                            self = .a
                            return
                        default:
                            break
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
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
                        try container.encode("a")
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test5 {
        @EnumCaseCoding(emptyPayloadOption: .emptyArray)
        case a
    }


    @Test("No Associated Values | Auto Case Key | Empty Array Payload")
    func test5() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let nestedContainer = try container.nestedUnkeyedContainer(forKey: .ka)
                            if nestedContainer.count == 0 {
                                self = .a
                                return
                            }
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case .a:
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode([DummyDecodableType](), forKey: .ka)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test6 {
        @EnumCaseCoding(emptyPayloadOption: .emptyObject)
        case a
    }


    @Test("No Associated Values | Auto Case Key | Empty Object Payload")
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let nestedContainer = try container.nestedContainer(keyedBy: $__unconditional_coding_keys.self, forKey: .ka)
                            if nestedContainer.allKeys.isEmpty {
                                self = .a
                                return
                            }
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case .a:
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(DummyDecodableType(), forKey: .ka)
                    }
                }
            }
            """#
        )
    }


    @EnumCodable
    enum Test7 {
        case a(value: Int)
    }


    @Test("Single Associated Value | Auto Case Key | Auto Payload")
    func test7() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let value = try container.decode(Int.self, forKey: .ka)
                            self = .a(value: value)
                            return
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case let .a(value0):
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(value0, forKey: .ka)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test8 {
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Auto Case Key | Auto Payload")
    func test8() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                enum $__coding_keys_root_a: String, CodingKey {
                    case kvalue = "value"
                    case k_1 = "_1"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .ka)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kvalue)
                            let value1 = try nestedContainer.decode(String.self, forKey: .k_1)
                            self = .a(value: value0, value1)
                            return
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
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
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .ka)
                        try nestedContainer.encode(value0, forKey: .kvalue)
                        try nestedContainer.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test9 {
        @EnumCaseCoding(payload: .singleValue)
        case a(value: Int)
    }


    @Test("Single Associated Value | Auto Case Key | Single Value Payload")
    func test9() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let value = try container.decode(Int.self, forKey: .ka)
                            self = .a(value: value)
                            return
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case let .a(value0):
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(value0, forKey: .ka)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test10 {
        @EnumCaseCoding(payload: .array)
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Auto Case Key | Array Payload")
    func test10() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .ka)
                            let value0 = try nestedContainer.decode(Int.self)
                            let value1 = try nestedContainer.decode(String.self)
                            self = .a(value: value0, value1)
                            return
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
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
                        var nestedContainer = container.nestedUnkeyedContainer(forKey: .ka)
                        try nestedContainer.encode(value0)
                        try nestedContainer.encode(value1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test11 {
        @EnumCaseCoding(payload: .object)
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Auto Case Key | Object Payload")
    func test11() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                enum $__coding_keys_root_a: String, CodingKey {
                    case kvalue = "value"
                    case k_1 = "_1"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .ka)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kvalue)
                            let value1 = try nestedContainer.decode(String.self, forKey: .k_1)
                            self = .a(value: value0, value1)
                            return
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
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
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .ka)
                        try nestedContainer.encode(value0, forKey: .kvalue)
                        try nestedContainer.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test12 {
        @EnumCaseCoding(payload: .object(keys: "key1", "key2"))
        case a(value: Int, _: String)
    }


    @Test("Multi Associated Values | Auto Case Key | Custom Object Payload")
    func test12() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    case ka = "a"
                }
                enum $__coding_keys_root_a: String, CodingKey {
                    case kkey1 = "key1"
                    case kkey2 = "key2"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .ka)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kkey1)
                            let value1 = try nestedContainer.decode(String.self, forKey: .kkey2)
                            self = .a(value: value0, value1)
                            return
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
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
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_a.self, forKey: .ka)
                        try nestedContainer.encode(value0, forKey: .kkey1)
                        try nestedContainer.encode(value1, forKey: .kkey2)
                    }
                }
            }
            """
        )
    }


    @EnumCodable
    enum Test13 {
        @EnumCaseCoding(caseKey: .auto, emptyPayloadOption: .emptyObject)
        case a
        @EnumCaseCoding(caseKey: "key_b", payload: .object(keys: "key1", "key2", "key3"))
        case b(value: Int, Int, _: String)
    }


    @Test("Mixed")
    func name() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(caseKey: .auto, emptyPayloadOption: .emptyObject)
                case a
                @EnumCaseCoding(caseKey: "key_b", payload: .object(keys: "key1", "key2", "key3"))
                case b(value: Int, Int, _: String)
            }
            """, 
            expandedSource: #"""
            enum Test {
                case a
                case b(value: Int, Int, _: String)
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
                    case ka = "a"
                    case kkey_b = "key_b"
                }
                enum $__coding_keys_root_b: String, CodingKey {
                    case kkey1 = "key1"
                    case kkey2 = "key2"
                    case kkey3 = "key3"
                }
                public init(from decoder: Decoder) throws {
                    if let container = try? decoder.container(keyedBy: $__coding_keys_root.self) {
                        guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                        switch caseKey {
                        case .ka:
                            let nestedContainer = try container.nestedContainer(keyedBy: $__unconditional_coding_keys.self, forKey: .ka)
                            if nestedContainer.allKeys.isEmpty {
                                self = .a
                                return
                            }
                        case .kkey_b:
                            let nestedContainer = try container.nestedContainer(keyedBy: $__coding_keys_root_b.self, forKey: .kkey_b)
                            let value0 = try nestedContainer.decode(Int.self, forKey: .kkey1)
                            let value1 = try nestedContainer.decode(Int.self, forKey: .kkey2)
                            let value2 = try nestedContainer.decode(String.self, forKey: .kkey3)
                            self = .b(value: value0, value1, value2)
                            return
                        }
                    }
                    switch Self.codingDefaultValue {
                    case .some(let defaultValue):
                        self = defaultValue
                        return
                    case .none:
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    switch self {
                    case .a:
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        try container.encode(DummyDecodableType(), forKey: .ka)
                    case let .b(value0, value1, value2):
                        var container = encoder.container(keyedBy: $__coding_keys_root.self)
                        var nestedContainer = container.nestedContainer(keyedBy: $__coding_keys_root_b.self, forKey: .kkey_b)
                        try nestedContainer.encode(value0, forKey: .kkey1)
                        try nestedContainer.encode(value1, forKey: .kkey2)
                        try nestedContainer.encode(value2, forKey: .kkey3)
                    }
                }
            }
            """#
        )
    }


    // @EnumCodable
    // enum TestE1 {

    // }


    @Test("Empty Enum")
    func testE1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
            }
            """, 
            expandedSource: """
            enum Test {
            }
            """,
            diagnostics: [
                .init(message: .codingMacro.enumCodable.emptyEnum(), line: 2, column: 6)
            ]
        )
    }


    // @EnumCodable
    // enum TestE2 {
    //     @EnumCaseCoding(caseKey: 1)
    //     case a
    // }


    @Test("Int Key")
    func testE2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(caseKey: 1)
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
                    message: .codingMacro.enumCodable.nonStringCaseKeyInExternalKeyedEnumCoding("1" as TokenSyntax), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE3 {
    //     @EnumCaseCoding(caseKey: 1.1)
    //     case a
    // }


    @Test("Float Key")
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(caseKey: 1.1)
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
                    message: .codingMacro.enumCodable.nonStringCaseKeyInExternalKeyedEnumCoding("1.1" as TokenSyntax), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE4 {
    //     @EnumCaseCoding(caseKey: "key")
    //     case a
    //     @EnumCaseCoding(caseKey: "key")
    //     case b
    //     case key
    // }


    @Test("Conflict Case Key", .disabled("Currently no way to control the order of dianostics"))
    func testE4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(key: "key")
                case a
                @EnumCaseCoding(key: "key")
                case b
                case key
            }
            """, 
            expandedSource: """
            enum Test {
                case a
                case b
                case key
            }
            """,
            diagnostics: [
                .init(message: .codingMacro.enumCodable.duplicatedCaseKey(with: ["b", "key"]), line: 3, column: 27),
                .init(message: .codingMacro.enumCodable.duplicatedCaseKey(with: ["a", "key"]), line: 5, column: 27),
                .init(message: .codingMacro.enumCodable.duplicatedCaseKey(with: ["a", "b"]), line: 7, column: 10)
            ]
        )
    }


    // @EnumCodable
    // enum TestE5 {
    //     @EnumCaseCoding(payload: .singleValue)
    //     case a
    // }


    @Test("Single Value Payload Setting on Case without Associated Values")
    func testE5() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(payload: .singleValue)
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
                    message: .codingMacro.enumCodable.payloadContentSettingOnCaseWithoutAssociatedValue(), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE6 {
    //     @EnumCaseCoding(payload: .object)
    //     case a
    // }


    @Test("Object Payload Setting on Case without Associated Values")
    func testE6() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(payload: .object)
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
                    message: .codingMacro.enumCodable.payloadContentSettingOnCaseWithoutAssociatedValue(), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE7 {
    //     @EnumCaseCoding(payload: .array)
    //     case a
    // }


    @Test("Array Payload Setting on Case without Associated Values")
    func testE7() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(payload: .array)
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
                    message: .codingMacro.enumCodable.payloadContentSettingOnCaseWithoutAssociatedValue(), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE8 {
    //     @EnumCaseCoding(emptyPayloadOption: .null)
    //     case b(Int)
    // }


    @Test("Null Payload Setting on Case with Associated Values")
    func testE8() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .null)
                case b(Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case b(Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.emptyPayloadSettingOnCaseWithAssociatedValues(), 
                    line: 3, 
                    column: 41
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE9 {
    //     @EnumCaseCoding(emptyPayloadOption: .nothing)
    //     case b(Int)
    // }


    @Test("No Payload Setting on Case with Associated Values")
    func testE9() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .nothing)
                case b(Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case b(Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.emptyPayloadSettingOnCaseWithAssociatedValues(), 
                    line: 3, 
                    column: 41
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE10 {
    //     @EnumCaseCoding(emptyPayloadOption: .emptyArray)
    //     case b(Int)
    // }


    @Test("Empty Array Payload Setting on Case with Associated Values")
    func testE10() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .emptyArray)
                case b(Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case b(Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.emptyPayloadSettingOnCaseWithAssociatedValues(), 
                    line: 3, 
                    column: 41
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE11 {
    //     @EnumCaseCoding(emptyPayloadOption: .emptyObject)
    //     case b(Int)
    // }


    @Test("Empty Object Payload Setting on Case with Associated Values")
    func testE11() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .emptyObject)
                case b(Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case b(Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.emptyPayloadSettingOnCaseWithAssociatedValues(), 
                    line: 3, 
                    column: 41
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE12 {
    //     @EnumCaseCoding(payload: .object(keys: "key"))
    //     case a(Int, Int)
    // }


    @Test("Less Object Payload Keys than Associated Values")
    func testE12() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(payload: .object(keys: "key"))
                case a(Int, Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(Int, Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.mismatchedKeyCountForObjectPayload(expected: 2, actual: 1), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE13 {
    //     @EnumCaseCoding(payload: .object(keys: "key1", "key2", "key3"))
    //     case a(Int, Int)
    // }


    @Test("More Object Payload Keys than Associated Values")
    func testE13() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(payload: .object(keys: "key1", "key2", "key3"))
                case a(Int, Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(Int, Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.mismatchedKeyCountForObjectPayload(expected: 2, actual: 3), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE14 {
    //     @EnumCaseCoding(payload: .object(keys: "key1", "key1"))
    //     case a(Int, Int)
    // }


    @Test("Conflict Object Payload Keys")
    func testE14() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
            enum Test {
                @EnumCaseCoding(payload: .object(keys: "key1", "key1"))
                case a(Int, Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(Int, Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .decorator.enumCaseCoding.duplicatedObjectPayloadKeys(["key1"]), 
                    line: 3, 
                    column: 38
                )
            ]
        )
    }


    // @EnumCodable
    // enum TestE15 {
    //     @EnumCaseCoding(unkeyedRawValuePayload: 1)
    //     case a
    // }


    @Test("Unkeyed Setting")
    func testE15() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable
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
                    message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(.externalKeyed), 
                    line: 3, 
                    column: 21
                )
            ]
        )
    }

}
