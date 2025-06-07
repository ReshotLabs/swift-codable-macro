import SwiftDiagnostics
import SwiftSyntax


extension EnumCodableMacro {

    enum Error {

        static func unsupportedEnumCodableOption(_ option: some SyntaxProtocol) -> CodingMacroImplBase.Error {
            .init(id: "unsupported_enum_codable_option", message: "EnumCodable option \(option.trimmed) is not supported")
        }

        static func mismatchedKeyCountForObjectPayload(expected: Int, actual: Int) -> CodingMacroImplBase.Error {
            .init(id: "mismatched_key_count_for_object_payload", message: "Internal Error: This case has \(expected) associatedValues, but \(actual) keys where specified for its object payload")
        }

        static func mismatchedAssociatedValueForSingleValuePayload() -> CodingMacroImplBase.Error {
            .init(id: "mismatched_associated_value_for_single_value_payload", message: "Internal Error: Single value payload requires exactly one associated value")
        }

        static func unkeyedSettingInKeyedEnumCoding(_ codableOption: EnumCodableOption) -> CodingMacroImplBase.Error {
            .init(id: "un_keyed_setting_in_keyed_enum_coding", message: "Unkeyed setting is not supported when codable option is \(codableOption)")
        }

        static func keyedSettingInUnkeyedEnumCoding() -> CodingMacroImplBase.Error {
            .init(id: "keyed_setting_in_un_keyed_enum_coding", message: "Keyed setting is not supported when codable option is .unKeyed")
        }

        static func nonStringCaseKeyInExternalKeyedEnumCoding(_ key: some SyntaxProtocol) -> CodingMacroImplBase.Error {
            .init(id: "non_string_case_key_in_external_keyed_enum_coding", message: "External keyed enum coding expects enum case key to be string, but got \(key.trimmed)")
        }

        static func objectKeyConflictedWithTypeKey() -> CodingMacroImplBase.Error {
            .init(id: "object_key_conflicted_with_type_key", message: "Keys in object payload must not conflicted with the enum case key")
        }

        static func nonObjectPayloadInInternalKeyedEnumCoding() -> CodingMacroImplBase.Error {
            .init(id: "non_object_payload_in_internal_keyed_enum_coding", message: "Internal keyed enum coding supports only object payload")
        }

        static func nonNothingEmptyPayloadOptionInInternalKeyedEnumConfig() -> CodingMacroImplBase.Error {
            .init(id: "non_nothing_empty_payload_option_in_internal_keyed_enum_coding", message: "Internal keyed enum coding supports only .nothing as empty payload option")
        }

        static func unexpectedCustomizationInRawValueEnumCoding() -> CodingMacroImplBase.Error {
            .init(id: "customization_in_raw_value_enum_coding", message: "Raw value enum coding forbid any customization")
        }

        static func duplicatedCaseKey(with cases: some Collection<TokenSyntax>) -> CodingMacroImplBase.Error {
            .init(id: "duplicate_case_key", message: "Case key duplicated with cases \(cases.map({ ".\($0.trimmed)" }).sorted().joined(separator: ", "))")
        }

        static func duplicatedUnkeyedRawValuePayload(with cases: some Collection<TokenSyntax>) -> CodingMacroImplBase.Error {
            .init(
                id: "duplicate_unkeyed_raw_value_payload", 
                message: "Unkeyed raw value payload duplicated with cases \(cases.map({ ".\($0.trimmed)" }).sorted().joined(separator: ", "))"
            )
        }

        static func emptyEnum() -> CodingMacroImplBase.Error {
            .init(id: "empty_enum", message: "Enum with no cases is not supported")
        }

        static func conflictedTypeAndPayloadKeys() -> CodingMacroImplBase.Error {
            .init(id: "conflicted_type_and_payload_keys", message: "Type key and payload key must not be the same")
        }

        static func payloadContentSettingOnCaseWithoutAssociatedValue() -> CodingMacroImplBase.Error {
            .init(id: "payload_setting_on_case_without_associated_value", message: "Payload setting is not supported on cases without associated values")
        }

        static func unkeyedPayloadSettingOnCaseWithoutAssociatedValues() -> CodingMacroImplBase.Error {
            .init(id: "unkeyed_payload_setting_on_case_without_associated_values", message: "Unkeyed payload setting is not supported on cases without associated values")
        }

        static func rawValueSettingOnCaseWithAssociatedValues() -> CodingMacroImplBase.Error {
            .init(id: "raw_value_setting_on_case_with_associated_values", message: "Raw value setting is not supported on cases with associated values")
        }

        static func emptyPayloadSettingOnCaseWithAssociatedValues() -> CodingMacroImplBase.Error {
            .init(id: "empty_payload_setting_on_case_with_associated_values", message: "Empty payload setting is not supported on cases with associated values")
        }

    }

}


extension CodingMacroImplBase.ErrorGroup {
    static var enumCodable: EnumCodableMacro.Error.Type {
        return EnumCodableMacro.Error.self
    }
}