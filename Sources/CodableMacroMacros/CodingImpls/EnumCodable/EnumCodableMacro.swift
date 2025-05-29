import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


final class EnumCodableMacro: CodingMacroImplBase, CodingMacroImplProtocol {

    static let supportedAttachedTypes: Set<AttachedType> = [.enum]
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("option", canIgnore: true)
    ]


    let enumCodableOption: EnumCodableOption
    let rawValueType: ExprSyntax?


    required init(
        macroNode: MacroInfo, 
        declGroup: DeclGroupSyntaxInfo, 
        context: any MacroExpansionContext
    ) throws {

        self.rawValueType = Self.inferRawValueType(from: declGroup)

        if let codableOptionArg = macroNode.arguments[0].first {
            self.enumCodableOption = try .init(from: codableOptionArg.expression)
        } else if rawValueType != nil {
            self.enumCodableOption = .rawValueCoded
        } else {
            self.enumCodableOption = .externalKeyed
        }

        try super.init(macroNode: macroNode, declGroup: declGroup, context: context)

    }


    func makeExtensionHeader() throws -> SyntaxNodeString {
        return "extension \(declGroup.name.trimmed): EnumCodableProtocol"
    }


    func makeDecls() throws -> [DeclSyntax] {

        guard !declGroup.enumCases.isEmpty else {
            throw .diagnostic(node: declGroup.name, message: .codingMacro.enumCodable.emptyEnum())
        }

        let enumCaseCodingSettings = try declGroup.enumCases.map { enumCase in 
            (
                caseInfo: enumCase,
                setting: try EnumCaseCodingMacro.processProperty(
                    enumCase, 
                    macroNodes: enumCase.attributes.filter { 
                        ($0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text).flatMap(DecoratorMacros.init(rawValue:)) == .enumCaseCoding 
                    },
                    context: context
                )
            )
        }

        let generator: any Generator

        switch enumCodableOption {
            case .externalKeyed:
                let codingSpecs = try processCasesForExternalKeyed(enumCaseCodingSettings)
                try requireNoDuplicatedKeys(in: codingSpecs)
                generator = ExternalKeyedGenerator(enumCaseCodingSpecs: codingSpecs)
            case .adjucentKeyed(let typeKey, let payloadKey):
                guard typeKey.text != payloadKey.text else {
                    throw .diagnostic(node: macroNode.rawSyntax, message: .codingMacro.enumCodable.conflictedTypeAndPayloadKeys())
                }
                let codingSpecs = try processCasesForAdjucentKeyed(enumCaseCodingSettings)
                try requireNoDuplicatedKeys(in: codingSpecs)
                generator = AdjucentKeyedGenerator(enumCaseCodingSpecs: codingSpecs, typeKey: typeKey, payloadKey: payloadKey)
            case .internalKeyed(let typeKey):
                let codingSpecs = try processCasesForInternalKeyed(
                    enumCaseCodingSettings, 
                    typeKey: typeKey
                )
                try requireNoDuplicatedKeys(in: codingSpecs)
                generator = InternalKeyedGenerator(enumCaseCodingSpecs: codingSpecs, typeKey: typeKey)
            case .unkeyed:
                let codingSpecs = try processCasesForUnKeyed(enumCaseCodingSettings)
                try requireNoDuplicatedRawValues(in: codingSpecs)
                generator = UnkeyedGenerator(enumCaseCodingSpecs: codingSpecs)
            case .rawValueCoded:
                try processCasesForRawValueCoded(enumCaseCodingSettings)
                generator = RawValueCodedGenerator()
        }

        return try buildDeclSyntaxList {
            try generator.generateCodingKeys()
            try generator.generateDecodeInitializer()
            try generator.generateEncodeMethod()
        }

    }


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

    }

}


extension CodingMacroImplBase.ErrorGroup {
    static var enumCodable: EnumCodableMacro.Error.Type {
        return EnumCodableMacro.Error.self
    }
}



extension EnumCodableMacro {

    

    private func inferedObjectPayloadKeys(of caseInfo: EnumCaseInfo) -> [TokenSyntax] {
        caseInfo.associatedValues.enumerated()
            .map { i, associatedValue in 
                associatedValue.label ?? "_\(raw: i)" as TokenSyntax
            }
    }


    private func processCasesForExternalKeyed(
        _ enumCaseCodingSettings: [(caseInfo: EnumCaseInfo, setting: EnumCaseCodingMacro.EnumCaseCodingSetting?)]
    ) throws(DiagnosticsError) -> [EnumCaseKeyedCodingSpec] {

        return try enumCaseCodingSettings.map { caseInfo, setting throws(DiagnosticsError) in

            var defaultPayload: EnumCaseKeyedCodingSpec.Payload {
                if caseInfo.associatedValues.isEmpty {
                    .empty(.null)
                } else if caseInfo.associatedValues.count == 1 {
                    .content(.singleValue)
                } else {
                    .content(.object(keys: inferedObjectPayloadKeys(of: caseInfo)))
                }
            }

            switch setting {
                case .none: 
                    return .init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: defaultPayload)
                case .some(.keyedPayload(.string(let key), .none)):
                    return .init(enumCaseInfo: caseInfo, key: .string(key), payload: defaultPayload)
                case .some(.keyedPayload(.string(let key), .empty(let emptyPayloadOption))):
                    return .init(
                        enumCaseInfo: caseInfo, 
                        key: .string(key), 
                        payload: .empty(.init(from: emptyPayloadOption))
                    )
                case .some(.keyedPayload(.string(let key), .content(let payloadContent))): 
                    return .init(
                        enumCaseInfo: caseInfo, 
                        key: .string(key), 
                        payload: .content(.init(from: payloadContent))
                    )
                case .some(.keyedPayload(let key, _)):
                    throw .diagnostic(
                        node: key.token, 
                        message: .codingMacro.enumCodable.nonStringCaseKeyInExternalKeyedEnumCoding(key.token)
                    )
                case .some(.unkeyedRawValue), .some(.unkeyedPayload):
                    throw .diagnostic(
                        node: caseInfo.name, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    )
            }

        }

    }


    private func processCasesForAdjucentKeyed(
        _ enumCaseCodingSettings: [(caseInfo: EnumCaseInfo, setting: EnumCaseCodingMacro.EnumCaseCodingSetting?)]
    ) throws(DiagnosticsError) -> [EnumCaseKeyedCodingSpec] {
        
        return try enumCaseCodingSettings.map { caseInfo, setting throws(DiagnosticsError) in

            var defaultPayload: EnumCaseKeyedCodingSpec.Payload {
                if caseInfo.associatedValues.isEmpty {
                    return .empty(.nothing)
                } else if caseInfo.associatedValues.count == 1 {
                    return .content(.singleValue)
                } else {
                    return .content(.object(keys: inferedObjectPayloadKeys(of: caseInfo)))
                }
            }

            switch setting {
                case .none: 
                    return .init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: defaultPayload)
                case .some(.keyedPayload(let key, .none)):
                    return .init(enumCaseInfo: caseInfo, key: key, payload: defaultPayload)
                case .some(.keyedPayload(let key, .empty(let emptyPayloadOption))): 
                    return .init(enumCaseInfo: caseInfo, key: key, payload: .empty(.init(from: emptyPayloadOption)))
                case .some(.keyedPayload(let key, .content(let payloadContent))): 
                    return .init(enumCaseInfo: caseInfo, key: key, payload: .content(.init(from: payloadContent)))
                case .some(.unkeyedRawValue), .some(.unkeyedPayload):
                    throw .diagnostic(
                        node: caseInfo.name, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    )
            }

        }

    }


    private func processCasesForInternalKeyed(
        _ enumCaseCodingSettings: [(caseInfo: EnumCaseInfo, setting: EnumCaseCodingMacro.EnumCaseCodingSetting?)],
        typeKey: TokenSyntax
    ) throws(DiagnosticsError) -> [EnumCaseKeyedCodingSpec] {

        func requireNoConflictedKeys(
            in objectPayloadKeys: [TokenSyntax], 
            associatedValues: [EnumCaseInfo.AssociatedValue], 
            isInferred: Bool
        ) throws(DiagnosticsError) {
            for (i, key) in objectPayloadKeys.enumerated() where key.trimmed.text == typeKey.trimmed.text {
                throw .diagnostic(
                    node: isInferred ? (associatedValues[i].label.map { Syntax($0) } ?? Syntax(associatedValues[i].type)) : Syntax(key), 
                    message: .codingMacro.enumCodable.objectKeyConflictedWithTypeKey()
                )
            }
        }
        
        return try enumCaseCodingSettings.map { caseInfo, setting throws(DiagnosticsError) in

            var defaultPayload: EnumCaseKeyedCodingSpec.Payload {
                get throws(DiagnosticsError) {
                    if caseInfo.associatedValues.isEmpty {
                        return .empty(.nothing)
                    } else {
                        let objectPayloadKeys = inferedObjectPayloadKeys(of: caseInfo)
                        try requireNoConflictedKeys(in: objectPayloadKeys, associatedValues: caseInfo.associatedValues, isInferred: true)
                        return .content(.object(keys: objectPayloadKeys))
                    }
                }
            }

            switch setting {
                case .none: 
                    return .init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: try defaultPayload) 
                case .some(.keyedPayload(let key, .none)):
                    return .init(enumCaseInfo: caseInfo, key: key, payload: try defaultPayload) 
                case .some(.keyedPayload(let key, .empty(.nothing))): 
                    return .init(
                        enumCaseInfo: caseInfo, 
                        key: key, 
                        payload: .empty(.nothing)
                    )
                case .some(.keyedPayload(let key, .content(.object(let objectPayloadKeys, let isInffered)))): 
                    try requireNoConflictedKeys(in: objectPayloadKeys, associatedValues: caseInfo.associatedValues, isInferred: isInffered)
                    return .init(
                        enumCaseInfo: caseInfo, 
                        key: key, 
                        payload: .content(.object(keys: objectPayloadKeys))
                    )
                case .some(.keyedPayload(_, .empty)):
                    throw .diagnostic(
                        node: caseInfo.name, 
                        message: .codingMacro.enumCodable.nonNothingEmptyPayloadOptionInInternalKeyedEnumConfig()
                    )
                case .some(.keyedPayload(_, .content)):
                    throw .diagnostic(
                        node: caseInfo.name, 
                        message: .codingMacro.enumCodable.nonObjectPayloadInInternalKeyedEnumCoding()
                    )
                case .some(.unkeyedRawValue), .some(.unkeyedPayload):
                    throw .diagnostic(
                        node: caseInfo.name, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    )
            }

        }

    }


    private func processCasesForUnKeyed(
        _ enumCaseCodingSettings: [(caseInfo: EnumCaseInfo, setting: EnumCaseCodingMacro.EnumCaseCodingSetting?)]
    ) throws(DiagnosticsError) -> [EnumCaseUnkeyedCodingSpec] {

        let (infferedRawValues, infferedRawValueType) = extractEnumCaseInferredRawValues()

        var specs = [EnumCaseUnkeyedCodingSpec]()

        for ((caseInfo, setting), infferedRawValue) in zip(enumCaseCodingSettings, infferedRawValues) {

            switch setting {
                case .none: 
                    if caseInfo.associatedValues.isEmpty {
                        specs.append(.init(enumCaseInfo: caseInfo, payload: .rawValue(type: infferedRawValueType, value: infferedRawValue)))
                    } else if caseInfo.associatedValues.count == 1 {
                        specs.append(.init(enumCaseInfo: caseInfo, payload: .content(.singleValue)))
                    } else {
                        let objectPayloadKeys = inferedObjectPayloadKeys(of: caseInfo)
                        specs.append(.init(enumCaseInfo: caseInfo, payload: .content(.object(keys: objectPayloadKeys))))
                    }
                case .some(.unkeyedRawValue(let type, let value)):
                    specs.append(.init(enumCaseInfo: caseInfo, payload: .rawValue(type: type, value: value)))
                case .some(.unkeyedPayload(let payloadContent)):
                    specs.append(.init(enumCaseInfo: caseInfo, payload: .content(.init(from: payloadContent))))
                case .some(.keyedPayload): 
                    throw .diagnostic(
                        node: caseInfo.name, 
                        message: .codingMacro.enumCodable.keyedSettingInUnkeyedEnumCoding()
                    )
            }

        }
        
        return specs

    }


    private func processCasesForRawValueCoded(
        _ enumCaseCodingSettings: [(caseInfo: EnumCaseInfo, setting: EnumCaseCodingMacro.EnumCaseCodingSetting?)]
    ) throws(DiagnosticsError) {

        let diagnostics = enumCaseCodingSettings.compactMap { caseInfo, setting in
            guard setting != nil else { return nil as Diagnostic? }
            return Diagnostic(node: caseInfo.name, message: .codingMacro.enumCodable.unexpectedCustomizationInRawValueEnumCoding())
        }

        guard diagnostics.isEmpty else {
            throw .diagnostics(diagnostics)
        }

    }

}



extension EnumCodableMacro {

    private func requireNoDuplicatedKeys(in enumCaseCodingSpecs: [EnumCaseKeyedCodingSpec]) throws {

        let duplicateKeyDianostics = enumCaseCodingSpecs
            .reduce(into: [LiteralValue.ResolvedValue:Set<EnumCaseKeyedCodingSpec>]()) { acc, spec in
                acc[spec.key.resolvedValue, default: []].insert(spec)
            }
            .compactMap { _, specs in 
                guard specs.count > 1 else { return nil as [Diagnostic]? }
                return specs.map { spec in 
                    Diagnostic(
                        node: spec.key.token, 
                        message: .codingMacro.enumCodable.duplicatedCaseKey(
                            with: specs.subtracting([spec]).map(\.enumCaseInfo.name)
                        )
                    )
                }
            }
            .flatMap(\.self)

        guard duplicateKeyDianostics.isEmpty else {
            throw .diagnostics(duplicateKeyDianostics)
        }

    }


    private func requireNoDuplicatedRawValues(in enumCaseUnkeyedCodingSpecs: [EnumCaseUnkeyedCodingSpec]) throws {

        let duplicateRawValueDianostics = enumCaseUnkeyedCodingSpecs
            .reduce(into: [String:[LiteralValue.ResolvedValue:Set<EnumCaseUnkeyedCodingSpec>]]()) { acc, spec in 
                guard case .rawValue(let type, let value) = spec.payload else { return }
                acc[type.trimmedDescription, default: [:]][value.resolvedValue, default: []].insert(spec)
            }
            .compactMap { _, rawValueCounts in
                rawValueCounts.compactMap { _, specs in
                    guard specs.count > 1 else { return nil as [Diagnostic]? }
                    return specs.compactMap { spec in 
                        guard case .rawValue(_, let value) = spec.payload else { return nil }
                        return Diagnostic(
                            node: context.isInSource(value.token) ? value.token : spec.enumCaseInfo.name, 
                            message: .codingMacro.enumCodable.duplicatedUnkeyedRawValuePayload(
                                with: specs.subtracting([spec]).map(\.enumCaseInfo.name)
                            )
                        )
                    }
                }.flatMap(\.self)
            }
            .flatMap(\.self)
        
        guard duplicateRawValueDianostics.isEmpty else {
            throw .diagnostics(duplicateRawValueDianostics)
        }

    }


    // private func requireNoDuplicatedMatchingRule(in enumCaseCodingSpecs: [EnumCaseKeyedCodingSpec]) throws {

    //     let duplicatedMatchingDianostics = enumCaseCodingSpecs
    //         .reduce(into: [String:Set<EnumCaseInfo>]()) { acc, spec in
    //             guard spec.key == nil, case .matching(let option) = spec.codingType else { return }
    //             let optionStr = switch option {
    //                 case .emptyArray: "emptyArray"
    //                 case .emptyObject: "emptyObject"
    //                 case .null: "null"
    //                 case .value(let type, let value): "\(type.trimmed): \(value.trimmed)"
    //             }
    //             acc[optionStr, default: []].insert(spec.enumCaseInfo)
    //         }
    //         .compactMap { _, enumCaseInfoSet in 
    //             guard enumCaseInfoSet.count > 1 else { return nil as [Diagnostic]? }
    //             return enumCaseInfoSet.map { enumCaseInfo in 
    //                 Diagnostic(
    //                     node: enumCaseInfo.name, 
    //                     message: .codingMacro.enumCodable.duplicateMatching(
    //                         with: enumCaseInfoSet.subtracting([enumCaseInfo]).map(\.name)
    //                     )
    //                 )
    //             }
    //         }
    //         .flatMap(\.self)

    //     guard duplicatedMatchingDianostics.isEmpty else {
    //         throw .diagnostics(duplicatedMatchingDianostics)
    //     }

    // }

}



extension EnumCodableMacro {

    static let supportedStringRawTypes: Set<String> = [
        "String"
    ]
    static let supportedIntRawTypes: Set<String> = [
        "Int", "UInt", "Int8", "UInt8", "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64", "Int128", "UInt128",
    ]
    static let supportedFloatRawTypes: Set<String> = [
        "Float", "Double", "Float16", "Float32", "Float64",
    ]


    private static func inferRawValueType(from declGroup: DeclGroupSyntaxInfo) -> ExprSyntax? {
        guard let type = declGroup.inheritance.first?.as(IdentifierTypeSyntax.self) else { return nil }
        if declGroup.enumCases.contains(where: { $0.rawValue != nil }) {
            return .init(TypeExprSyntax(type: type))
        }
        if 
            Self.supportedStringRawTypes.contains(type.trimmedDescription) 
            || Self.supportedIntRawTypes.contains(type.trimmedDescription) 
            || Self.supportedFloatRawTypes.contains(type.trimmedDescription) 
        {
            return .init(TypeExprSyntax(type: type))
        }
        return nil
    }


    private func extractEnumCaseInferredRawValues() -> (rawValues: [LiteralValue], type: ExprSyntax) {

        guard let rawValueType else { 
            return (declGroup.enumCases.map { .string($0.name) }, "String")
        }

        if Self.supportedStringRawTypes.contains(rawValueType.trimmedDescription) {

            return (
                declGroup.enumCases.map { $0.rawValue ?? .string($0.name) },
                rawValueType
            )

        } else if Self.supportedIntRawTypes.contains(rawValueType.trimmedDescription) {

            var counter = 0
            var rawValues = [LiteralValue]()

            for c in declGroup.enumCases {
                rawValues.append(c.rawValue ?? .int("\(raw: counter)"))
                counter = (c.rawValue?.resolvedValue.number.map(Int.init) ?? counter) + 1
            }

            return (rawValues, rawValueType)

        } else if Self.supportedFloatRawTypes.contains(rawValueType.trimmedDescription) {

            var counter = 0.0
            var rawValues = [LiteralValue]()

            for c in declGroup.enumCases {
                rawValues.append(c.rawValue ?? .float("\(raw: counter)"))
                counter = floor((c.rawValue?.resolvedValue.number) ?? counter)  + 1
            }

            return (rawValues, rawValueType)

        }

        return (declGroup.enumCases.map { .string($0.name) }, "String")

    }

}