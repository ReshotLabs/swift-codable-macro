import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder


extension EnumCodableMacro {

    func extractCodingSpecForExternalKeyed(
        _ enumCaseCodingSettings: [EnumCaseRawCodingSetting]
    ) throws(DiagnosticsError) -> [KeyedCaseCodingSpec] {

        let infoList = try enumCaseCodingSettings.map { caseInfo, setting throws(DiagnosticsError) in

            var defaultPayload: Payload {
                if caseInfo.associatedValues.isEmpty {
                    .empty(.null)
                } else if caseInfo.associatedValues.count == 1 {
                    .content(.singleValue)
                } else {
                    .content(.object(inferingKeysFrom: caseInfo.associatedValues))
                }
            }

            switch setting {
                case .none: 
                    return .init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: defaultPayload)
                case .some(.keyed(let key, let payload, _)):
                    let key = key ?? .string(caseInfo.name)
                    guard key.kind == .string else {
                        throw .diagnostic(
                            node: key.token, 
                            message: .codingMacro.enumCodable.nonStringCaseKeyInExternalKeyedEnumCoding(key.token)
                        )
                    }
                    switch payload {
                        case .none:
                            return .init(enumCaseInfo: caseInfo, key: key, payload: defaultPayload)
                        case .some(.content(.object(.none, _))):
                            return .init(enumCaseInfo: caseInfo, key: key, payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues)))
                        case .some(let payload):
                            return .init(enumCaseInfo: caseInfo, key: key, payload: .init(payload))
                    }
                case .some(.unkeyed(_, let rawSyntax)):
                    throw .diagnostic(
                        node: rawSyntax, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    )
            }

        } as [KeyedCaseCodingSpec]

        try requireNoDuplicatedKeys(in: infoList)

        return infoList

    }


    func extractCodingSpecForAdjucentKeyed(
        _ enumCaseCodingSettings: [EnumCaseRawCodingSetting]
    ) throws(DiagnosticsError) -> [KeyedCaseCodingSpec] {
        
        let infoList = try enumCaseCodingSettings.map { caseInfo, setting throws(DiagnosticsError) in

            var defaultPayload: Payload {
                if caseInfo.associatedValues.isEmpty {
                    return .empty(.nothing)
                } else if caseInfo.associatedValues.count == 1 {
                    return .content(.singleValue)
                } else {
                    return .content(.object(inferingKeysFrom: caseInfo.associatedValues))
                }
            }

            switch setting {
                case .none: 
                    return .init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: defaultPayload)
                case .some(.keyed(let key, .none, _)):
                    return .init(enumCaseInfo: caseInfo, key: key ?? .string(caseInfo.name), payload: defaultPayload)
                case .some(.keyed(let key, .content(.object(.none, _)), _)):
                    return .init(
                        enumCaseInfo: caseInfo, 
                        key: key ?? .string(caseInfo.name), 
                        payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues))
                    )
                case .some(.keyed(let key, .some(let payload), _)): 
                    return .init(enumCaseInfo: caseInfo, key: key ?? .string(caseInfo.name), payload: .init(payload))
                case .some(.unkeyed(_, let rawSyntax)):
                    throw .diagnostic(
                        node: rawSyntax, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    )
            }

        } as [KeyedCaseCodingSpec]

        try requireNoDuplicatedKeys(in: infoList)

        return infoList

    }


    func extractCodingSpecForInternalKeyed(
        _ enumCaseCodingSettings: [EnumCaseRawCodingSetting],
        typeKey: TokenSyntax
    ) throws(DiagnosticsError) -> [KeyedCaseCodingSpec] {
        
        let infoList = try enumCaseCodingSettings.map { caseInfo, setting throws(DiagnosticsError) in

            func requireNoConflictWithTypeKey(
                in objectPayloadKeys: [ObjectPayloadKey]
            ) throws(DiagnosticsError) {
                for key in objectPayloadKeys where key.trimmed.text == typeKey.trimmed.text {
                    let provider: Syntax
                    switch key {
                        case .named(let token): provider = Syntax(token)
                        case .indexed(let indexToken): 
                            let index = indexToken.index
                            guard index < caseInfo.associatedValues.count else {
                                throw .diagnostic(
                                    node: caseInfo.name, 
                                    message: .internal.init(message: "Unexpected object key with index \(index), which is out of bounds for associated values of case \(caseInfo.name.trimmed)")
                                )
                            }
                            provider = Syntax(caseInfo.associatedValues[index].type)
                    }
                    throw .diagnostic(node: provider,message: .codingMacro.enumCodable.objectKeyConflictedWithTypeKey())
                }
            }

            var defaultPayload: Payload {
                get throws(DiagnosticsError) {
                    if caseInfo.associatedValues.isEmpty {
                        return .empty(.nothing)
                    } else {
                        let objectPayloadKeys = ObjectPayloadKey.infer(from: caseInfo.associatedValues)
                        try requireNoConflictWithTypeKey(in: objectPayloadKeys)
                        return .content(.object(keys: objectPayloadKeys))
                    }
                }
            }

            switch setting {
                case .none: 
                    return .init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: try defaultPayload) 
                case .some(.keyed(let key, .none, _)):
                    return .init(enumCaseInfo: caseInfo, key: key ?? .string(caseInfo.name), payload: try defaultPayload) 
                case .some(.keyed(let key, .empty(.nothing), _)): 
                    return .init(
                        enumCaseInfo: caseInfo, 
                        key: key ?? .string(caseInfo.name), 
                        payload: .empty(.nothing)
                    )
                case .some(.keyed(let key, .content(.object(let objectPayloadKeys, _)), _)): 
                    let objectPayloadKeys = objectPayloadKeys?.map { .named($0) } ?? ObjectPayloadKey.infer(from: caseInfo.associatedValues)
                    try requireNoConflictWithTypeKey(in: objectPayloadKeys)
                    return .init(
                        enumCaseInfo: caseInfo, 
                        key: key ?? .string(caseInfo.name), 
                        payload: .content(.object(keys: objectPayloadKeys))
                    )
                case .some(.keyed(_, .empty(let emptyPayloadOption), _)):
                    throw .diagnostic(
                        node: emptyPayloadOption.rawSyntax, 
                        message: .codingMacro.enumCodable.nonNothingEmptyPayloadOptionInInternalKeyedEnumConfig()
                    )
                case .some(.keyed(_, .content(let payloadContent), _)):
                    throw .diagnostic(
                        node: payloadContent.rawSyntax, 
                        message: .codingMacro.enumCodable.nonObjectPayloadInInternalKeyedEnumCoding()
                    )
                case .some(.unkeyed(_, let rawSyntax)):
                    throw .diagnostic(
                        node: rawSyntax, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    )
            }

        } as [KeyedCaseCodingSpec]

        try requireNoDuplicatedKeys(in: infoList)

        return infoList

    }


    func extractCodingSpecForUnKeyed(
        _ enumCaseCodingSettings: [EnumCaseRawCodingSetting]
    ) throws(DiagnosticsError) -> [UnkeyedCaseCodingSpec] {

        let (infferedRawValues, infferedRawValueType) = extractEnumCaseInferredRawValues()

        var specs = [UnkeyedCaseCodingSpec]()

        for ((caseInfo, setting), infferedRawValue) in zip(enumCaseCodingSettings, infferedRawValues) {

            switch setting {
                case .none: 
                    if caseInfo.associatedValues.isEmpty {
                        specs.append(.init(enumCaseInfo: caseInfo, payload: .rawValue(type: infferedRawValueType, value: infferedRawValue)))
                    } else if caseInfo.associatedValues.count == 1 {
                        specs.append(.init(enumCaseInfo: caseInfo, payload: .content(.singleValue)))
                    } else {
                        specs.append(.init(enumCaseInfo: caseInfo, payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues))))
                    }
                case .some(.unkeyed(.rawValue(let type, let value), _)):
                    specs.append(.init(enumCaseInfo: caseInfo, payload: .rawValue(type: type, value: value)))
                case .some(.unkeyed(.content(.object(.none, _)), _)):
                    specs.append(.init(enumCaseInfo: caseInfo, payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues))))
                case .some(.unkeyed(.content(let payloadContent), _)):
                    specs.append(.init(enumCaseInfo: caseInfo, payload: .content(.init(payloadContent))))
                case .some(.keyed(_, _, let rawSynax)): 
                    throw .diagnostic(
                        node: rawSynax, 
                        message: .codingMacro.enumCodable.keyedSettingInUnkeyedEnumCoding()
                    )
            }

        }

        try requireNoDuplicatedRawValues(in: specs)
        
        return specs

    }


    func validateSettingsForRawValueCoded(
        _ enumCaseCodingSettings: [EnumCaseRawCodingSetting]
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

    private func requireNoDuplicatedKeys(in enumCaseCodingSpecs: [KeyedCaseCodingSpec]) throws(DiagnosticsError) {

        let duplicateKeyDianostics = enumCaseCodingSpecs
            .reduce(into: [LiteralValue.ResolvedValue:Set<KeyedCaseCodingSpec>]()) { acc, spec in
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


    private func requireNoDuplicatedRawValues(in enumCaseUnkeyedCodingSpecs: [UnkeyedCaseCodingSpec]) throws(DiagnosticsError) {

        let duplicateRawValueDianostics = enumCaseUnkeyedCodingSpecs
            .reduce(into: [String:[LiteralValue.ResolvedValue:Set<UnkeyedCaseCodingSpec>]]()) { acc, spec in 
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

}