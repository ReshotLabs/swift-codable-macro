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

    @Suite("Test EnumCodable (Internal Keyed)")
    final class EnumCodableInternalKeyedTest: CodingExpansionTest {}

}



extension CodingExpansionTest.EnumCodableInternalKeyedTest {

    @EnumCodable(option: .internalKeyed())
    enum Test1 {
        case a, b
    }


    @Test("Auto Type Key | No Associated Values | Auto Case Key | Auto Payload")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
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
    

    @EnumCodable(option: .internalKeyed())
    enum Test2 {
        @EnumCaseCoding(key: "key_a")
        case a
    }


    @Test("Auto Type Key | No Associated Values | String Case Key | Auto Payload")
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
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


    @EnumCodable(option: .internalKeyed())
    enum Test3 {
        @EnumCaseCoding(key: 1)
        case a
    }


    @Test("Auto Type Key | No Associated Values | Int Case Key | Auto Payload")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
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


    @EnumCodable(option: .internalKeyed())
    enum Test4 {
        @EnumCaseCoding(key: 1.1)
        case a
    }


    @Test("Auto Type Key | No Associated Values | Float Case Key | Auto Payload")
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
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


    @EnumCodable(option: .internalKeyed())
    enum Test5 {
        @EnumCaseCoding(emptyPayloadOption: .nothing)
        case a
    }


    @Test("Auto Type Key | No Associated Values | Auto Case Key | No Payload")
    func test5() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
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


    @EnumCodable(option: .internalKeyed())
    enum Test6 {
        case a(value: Int)
    }


    @Test("Auto Type Key | Single Associated Values | Auto Case Key | Auto Payload")
    func test6() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
                    case kvalue = "value"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let value0 = try container.decode(Int.self, forKey: .kvalue)
                            self = .a(value: value0)
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
                        try container.encode(value0, forKey: .kvalue)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .internalKeyed())
    enum Test7 {
        case a(value: Int, _: String)
    }


    @Test("Auto Type Key | Multi Associated Values | Auto Case Key | Auto Payload")
    func test7() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
                    case k_1 = "_1", kvalue = "value"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let value0 = try container.decode(Int.self, forKey: .kvalue)
                            let value1 = try container.decode(String.self, forKey: .k_1)
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
                        try container.encode(value0, forKey: .kvalue)
                        try container.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .internalKeyed())
    enum Test8 {
        @EnumCaseCoding(payload: .object)
        case a(value: Int, _: String)
    }


    @Test("Auto Type Key | Multi Associated Values | Auto Case Key | Object Payload")
    func test8() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
                    case k_1 = "_1", kvalue = "value"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let value0 = try container.decode(Int.self, forKey: .kvalue)
                            let value1 = try container.decode(String.self, forKey: .k_1)
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
                        try container.encode(value0, forKey: .kvalue)
                        try container.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .internalKeyed())
    enum Test9 {
        @EnumCaseCoding(payload: .object(keys: "key1", "key2"))
        case a(value: Int, _: String)
    }


    @Test("Auto Type Key | Multi Associated Values | Auto Case Key | Custom Object Payload")
    func test9() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    case ktype = "type"
                    case kkey1 = "key1", kkey2 = "key2"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .ktype) {
                        switch type {
                        case "a":
                            let value0 = try container.decode(Int.self, forKey: .kkey1)
                            let value1 = try container.decode(String.self, forKey: .kkey2)
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
                        try container.encode(value0, forKey: .kkey1)
                        try container.encode(value1, forKey: .kkey2)
                    }
                }
            }
            """
        )
    }


    @EnumCodable(option: .internalKeyed(typeKey: "case"))
    enum Test10 {
        @EnumCaseCoding(payload: .object)
        case a(value: Int, _: String)
    }


    @Test("Custom Type Key | Multi Associated Values | Auto Case Key | Object Payload")
    func test10() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed(typeKey: "case"))
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
                    case kcase = "case"
                    case k_1 = "_1", kvalue = "value"
                }
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: $__coding_keys_root.self)
                    if let type = try? container.decode(String.self, forKey: .kcase) {
                        switch type {
                        case "a":
                            let value0 = try container.decode(Int.self, forKey: .kvalue)
                            let value1 = try container.decode(String.self, forKey: .k_1)
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
                        try container.encode(value0, forKey: .kvalue)
                        try container.encode(value1, forKey: .k_1)
                    }
                }
            }
            """
        )
    }

}



extension CodingExpansionTest.EnumCodableInternalKeyedTest {

    // @EnumCodable(option: .internalKeyed())
    // enum TestE1 {
    //     @EnumCaseCoding(emptyPayloadOption: .null)
    //     case a
    // }


    @Test("Null Payload")
    func testE1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    message: .codingMacro.enumCodable.nonNothingEmptyPayloadOptionInInternalKeyedEnumConfig(), 
                    line: 3, 
                    column: 41
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed())
    // enum TestE2 {
    //     @EnumCaseCoding(emptyPayloadOption: .emptyArray)
    //     case a
    // }


    @Test("Empty Array Payload")
    func testE2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .emptyArray)
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
                    message: .codingMacro.enumCodable.nonNothingEmptyPayloadOptionInInternalKeyedEnumConfig(), 
                    line: 3, 
                    column: 41
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed())
    // enum TestE3 {
    //     @EnumCaseCoding(emptyPayloadOption: .emptyObject)
    //     case a
    // }


    @Test("Empty Object Payload")
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
            enum Test {
                @EnumCaseCoding(emptyPayloadOption: .emptyObject)
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
                    message: .codingMacro.enumCodable.nonNothingEmptyPayloadOptionInInternalKeyedEnumConfig(), 
                    line: 3, 
                    column: 41
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed())
    // enum TestE4 {
    //     @EnumCaseCoding(payload: .singleValue)
    //     case a(Int)
    // }


    @Test("Single Value Payload")
    func testE4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
            enum Test {
                @EnumCaseCoding(payload: .singleValue)
                case a(Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.nonObjectPayloadInInternalKeyedEnumCoding(), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed())
    // enum TestE5 {
    //     @EnumCaseCoding(payload: .array)
    //     case a(Int)
    // }


    @Test("Array Payload")
    func testE5() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
            enum Test {
                @EnumCaseCoding(payload: .array)
                case a(Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.nonObjectPayloadInInternalKeyedEnumCoding(), 
                    line: 3, 
                    column: 30
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed(typeKey: "_0"))
    // enum TestE6 {
    //     case a(Int, Int)
    // }


    @Test("Conflict Type Key and Object Payload Keys 1")
    func testE6() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed(typeKey: "_0"))
            enum Test {
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
                    message: .codingMacro.enumCodable.objectKeyConflictedWithTypeKey(), 
                    line: 3, 
                    column: 12
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed())
    // enum TestE7 {
    //     case a(Int, type: Int)
    // }


    @Test("Conflict Type Key and Object Payload Keys 2")
    func testE7() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
            enum Test {
                case a(Int, type: Int)
            }
            """, 
            expandedSource: """
            enum Test {
                case a(Int, type: Int)
            }
            """,
            diagnostics: [
                .init(
                    message: .codingMacro.enumCodable.objectKeyConflictedWithTypeKey(), 
                    line: 3, 
                    column: 17
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed())
    // enum TestE8 {
    //     @EnumCaseCoding(payload: .object(keys: "type", "key"))
    //     case a(Int, Int)
    // }


    @Test("Conflict Type Key and Object Payload Keys 3")
    func testE8() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
            enum Test {
                @EnumCaseCoding(payload: .object(keys: "type", "key"))
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
                    message: .codingMacro.enumCodable.objectKeyConflictedWithTypeKey(), 
                    line: 3, 
                    column: 45
                )
            ]
        )
    }


    // @EnumCodable(option: .internalKeyed())
    // enum TestE9 {
    //     @EnumCaseCoding(unkeyedRawValuePayload: 1)
    //     case a
    // }


    @Test("Unkeyed Setting")
    func testE9() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .internalKeyed())
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
                    message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(.internalKeyed()), 
                    line: 3, 
                    column: 21
                )
            ]
        )
    }

}