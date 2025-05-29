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

    @Suite("Test EnumCodable (Raw Value Coded)")
    final class EnumCodableRawValueCodedTest: CodingExpansionTest {}

}



extension CodingExpansionTest.EnumCodableRawValueCodedTest {

    @EnumCodable(option: .rawValueCoded)
    enum Test1: Int {
        case a = 1
        case b
    }


    @Test("Int Raw Value")
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .rawValueCoded)
            enum Test: Int {
                case a = 1
                case b
            }
            """, 
            expandedSource: """
            enum Test: Int {
                case a = 1
                case b
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    let rawValue = try Self.RawValue(from: decoder)
                    guard let value = Self(rawValue: rawValue) as Self? else {
                        switch Self.codingDefaultValue {
                        case .value(let defaultValue):
                            self = defaultValue
                            return
                        case .none:
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                    }
                    self = value
                }
                public func encode(to encoder: Encoder) throws {
                    try self.rawValue.encode(to: encoder)
                }
            }
            """
        )
    }


    @EnumCodable(option: .rawValueCoded)
    enum Test2: String {
        case a = ""
        case b = "raw_b"
    }


    @Test("String Raw Value")
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .rawValueCoded)
            enum Test: String {
                case a = ""
                case b = "raw_b"
            }
            """, 
            expandedSource: """
            enum Test: String {
                case a = ""
                case b = "raw_b"
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    let rawValue = try Self.RawValue(from: decoder)
                    guard let value = Self(rawValue: rawValue) as Self? else {
                        switch Self.codingDefaultValue {
                        case .value(let defaultValue):
                            self = defaultValue
                            return
                        case .none:
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                    }
                    self = value
                }
                public func encode(to encoder: Encoder) throws {
                    try self.rawValue.encode(to: encoder)
                }
            }
            """
        )
    }


    @EnumCodable(option: .rawValueCoded)
    enum Test3: StringExpressible {
        case a = ""
        case b = "raw_b"
    }


    @Test("Custom String Raw Value")
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .rawValueCoded)
            enum Test: StringExpressible {
                case a = ""
                case b = "raw_b"
            }
            """, 
            expandedSource: """
            enum Test: StringExpressible {
                case a = ""
                case b = "raw_b"
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    let rawValue = try Self.RawValue(from: decoder)
                    guard let value = Self(rawValue: rawValue) as Self? else {
                        switch Self.codingDefaultValue {
                        case .value(let defaultValue):
                            self = defaultValue
                            return
                        case .none:
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                    }
                    self = value
                }
                public func encode(to encoder: Encoder) throws {
                    try self.rawValue.encode(to: encoder)
                }
            }
            """
        )
    }


    @EnumCodable(option: .rawValueCoded)
    enum Test4: RawRepresentable {
        case a, b
        init(rawValue: String) {
            switch rawValue {
                case "a": self = .a
                case "b": self = .b
                default: fatalError()
            }
        }
        var rawValue: String {
            switch self {
                case .a: return "a"
                case .b: return "b"
            }
        }
    }


    @Test("Custom RawRepresentable")
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .rawValueCoded)
            enum Test: RawRepresentable {
                case a, b
                init(rawValue: String) {
                    switch rawValue {
                        case "a": self = .a
                        case "b": self = .b
                        default: fatalError()
                    }
                }
                var rawValue: String {
                    switch self {
                        case .a: return "a"
                        case .b: return "b"
                    }
                }
            }
            """, 
            expandedSource: """
            enum Test: RawRepresentable {
                case a, b
                init(rawValue: String) {
                    switch rawValue {
                        case "a": self = .a
                        case "b": self = .b
                        default: fatalError()
                    }
                }
                var rawValue: String {
                    switch self {
                        case .a: return "a"
                        case .b: return "b"
                    }
                }
            }

            extension Test: EnumCodableProtocol {
                public init(from decoder: Decoder) throws {
                    let rawValue = try Self.RawValue(from: decoder)
                    guard let value = Self(rawValue: rawValue) as Self? else {
                        switch Self.codingDefaultValue {
                        case .value(let defaultValue):
                            self = defaultValue
                            return
                        case .none:
                            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                        }
                    }
                    self = value
                }
                public func encode(to encoder: Encoder) throws {
                    try self.rawValue.encode(to: encoder)
                }
            }
            """
        )
    }


    struct StringExpressible: ExpressibleByStringLiteral, Sendable, Codable, Equatable {
        init(stringLiteral value: String) {}
    }


    // @EnumCodable(option: .rawValueCoded)
    // enum TestE1 {
    //     @EnumCaseCoding(key: "key")
    //     case a
    // }


    @Test("Customization 1")
    func testE1() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .rawValueCoded)
            enum Test {
                @EnumCaseCoding(key: "key")
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
                    message: .codingMacro.enumCodable.unexpectedCustomizationInRawValueEnumCoding(), 
                    line: 4, 
                    column: 10
                )
            ]
        )
    }


    // @EnumCodable(option: .rawValueCoded)
    // enum TestE2 {
    //     @EnumCaseCoding(unkeyedRawValuePayload: "key")
    //     case a
    // }


    @Test("Customization 2")
    func testE2() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .rawValueCoded)
            enum Test {
                @EnumCaseCoding(unkeyedRawValuePayload: "key")
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
                    message: .codingMacro.enumCodable.unexpectedCustomizationInRawValueEnumCoding(), 
                    line: 4, 
                    column: 10
                )
            ]
        )
    }


    // @EnumCodable(option: .rawValueCoded)
    // enum TestE3 {
    //     @EnumCaseCoding(emptyPayloadOption: .emptyArray)
    //     case a
    // }


    @Test("Customization 3")
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @EnumCodable(option: .rawValueCoded)
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
                    message: .codingMacro.enumCodable.unexpectedCustomizationInRawValueEnumCoding(), 
                    line: 4, 
                    column: 10
                )
            ]
        )
    }

}