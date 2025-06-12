import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder


extension EnumCodableMacro {

    func extractCodingSpecForExternalKeyed(
        _ enumCaseCodingSettings: DiagnosticResultSequence<EnumCaseRawCodingSetting>
    ) throws(DiagnosticsError) -> DiagnosticResultSequence<KeyedCaseCodingSpec> {

        return enumCaseCodingSettings.flatMapResult { caseInfo, setting in

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
                    return .success(.init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: defaultPayload))
                case .some(.keyed(let key, let payload, _)):
                    let key = key ?? .string(caseInfo.name)
                    guard key.kind == .string else {
                        return .failure(.diagnostic(
                            node: key.token, 
                            message: .codingMacro.enumCodable.nonStringCaseKeyInExternalKeyedEnumCoding(key.token)
                        ))
                    }
                    switch payload {
                        case .none:
                            return .success(.init(enumCaseInfo: caseInfo, key: key, payload: defaultPayload))
                        case .some(.content(.object(.none, _))):
                            return .success(.init(enumCaseInfo: caseInfo, key: key, payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues))))
                        case .some(let payload):
                            return .success(.init(enumCaseInfo: caseInfo, key: key, payload: .init(payload)))
                    }
                case .some(.unkeyed(_, let rawSyntax)):
                    return .failure(.diagnostic(
                        node: rawSyntax, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    ))
            }

        }.apply(requireNoDuplicatedKeys)

    }


    func extractCodingSpecForAdjucentKeyed(
        _ enumCaseCodingSettings: DiagnosticResultSequence<EnumCaseRawCodingSetting>
    ) -> DiagnosticResultSequence<KeyedCaseCodingSpec> {
        
        return enumCaseCodingSettings.flatMapResult { caseInfo, setting in

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
                    return .success(.init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: defaultPayload))
                case .some(.keyed(let key, .none, _)):
                    return .success(.init(enumCaseInfo: caseInfo, key: key ?? .string(caseInfo.name), payload: defaultPayload))
                case .some(.keyed(let key, .content(.object(.none, _)), _)):
                    return .success(.init(
                        enumCaseInfo: caseInfo, 
                        key: key ?? .string(caseInfo.name), 
                        payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues))
                    ))
                case .some(.keyed(let key, .some(let payload), _)): 
                    return .success(.init(enumCaseInfo: caseInfo, key: key ?? .string(caseInfo.name), payload: .init(payload)))
                case .some(.unkeyed(_, let rawSyntax)):
                    return .failure(.diagnostic(
                        node: rawSyntax, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    ))
            }

        }.apply(requireNoDuplicatedKeys)

    }


    func extractCodingSpecForInternalKeyed(
        _ enumCaseCodingSettings: DiagnosticResultSequence<EnumCaseRawCodingSetting>,
        typeKey: TokenSyntax
    ) -> DiagnosticResultSequence<KeyedCaseCodingSpec> {
        
        return enumCaseCodingSettings.flatMapResult { caseInfo, setting in

            func requireNoConflictWithTypeKey(
                in objectPayloadKeys: [ObjectPayloadKey]
            ) -> DiagnosticsError? {
                for key in objectPayloadKeys where key.trimmed.text == typeKey.trimmed.text {
                    let provider: Syntax
                    switch key {
                        case .named(let token): provider = Syntax(token)
                        case .indexed(let indexToken): 
                            let index = indexToken.index
                            guard index < caseInfo.associatedValues.count else {
                                return .diagnostic(
                                    node: caseInfo.name, 
                                    message: .internal.init(message: "Unexpected object key with index \(index), which is out of bounds for associated values of case \(caseInfo.name.trimmed)")
                                )
                            }
                            provider = Syntax(caseInfo.associatedValues[index].type)
                    }
                    return .diagnostic(node: provider,message: .codingMacro.enumCodable.objectKeyConflictedWithCaseFieldName())
                }
                return nil 
            }

            var defaultPayload: DiagnosticResult<Payload> {
                if caseInfo.associatedValues.isEmpty {
                    return .success(.empty(.nothing))
                } else {
                    let objectPayloadKeys = ObjectPayloadKey.infer(from: caseInfo.associatedValues)
                    if let error = requireNoConflictWithTypeKey(in: objectPayloadKeys) {
                        return .failure(error)
                    } else {
                        return .success(.content(.object(keys: objectPayloadKeys)))
                    }
                }
            }

            switch setting {
                case .none: 
                    return defaultPayload.map { payload in
                        .init(enumCaseInfo: caseInfo, key: .string(caseInfo.name), payload: payload)
                    }
                case .some(.keyed(let key, .none, _)):
                    return defaultPayload.map { payload in
                        .init(enumCaseInfo: caseInfo, key: key ?? .string(caseInfo.name), payload: payload)
                    }
                case .some(.keyed(let key, .empty(.nothing), _)): 
                    return .success(.init(
                        enumCaseInfo: caseInfo, 
                        key: key ?? .string(caseInfo.name), 
                        payload: .empty(.nothing)
                    ))
                case .some(.keyed(let key, .content(.object(let objectPayloadKeys, _)), _)): 
                    let objectPayloadKeys = objectPayloadKeys?.map { .named($0) } ?? ObjectPayloadKey.infer(from: caseInfo.associatedValues)
                    if let error = requireNoConflictWithTypeKey(in: objectPayloadKeys) {
                        return .failure(error)
                    }
                    return .success(.init(
                        enumCaseInfo: caseInfo, 
                        key: key ?? .string(caseInfo.name), 
                        payload: .content(.object(keys: objectPayloadKeys))
                    ))
                case .some(.keyed(_, .empty(let emptyPayloadOption), _)):
                    return .failure(.diagnostic(
                        node: emptyPayloadOption.rawSyntax, 
                        message: .codingMacro.enumCodable.nonNothingEmptyPayloadOptionInInternalKeyedEnumConfig()
                    ))
                case .some(.keyed(_, .content(let payloadContent), _)):
                    return .failure(.diagnostic(
                        node: payloadContent.rawSyntax, 
                        message: .codingMacro.enumCodable.nonObjectPayloadInInternalKeyedEnumCoding()
                    ))
                case .some(.unkeyed(_, let rawSyntax)):
                    return .failure(.diagnostic(
                        node: rawSyntax, 
                        message: .codingMacro.enumCodable.unkeyedSettingInKeyedEnumCoding(enumCodableOption)
                    ))
            }

        }.apply(requireNoDuplicatedKeys)

    }


    func extractCodingSpecForUnKeyed(
        _ enumCaseCodingSettings: DiagnosticResultSequence<EnumCaseRawCodingSetting>
    ) throws(DiagnosticsError) -> DiagnosticResultSequence<UnkeyedCaseCodingSpec> {

        let (infferedRawValues, infferedRawValueType) = extractEnumCaseInferredRawValues()

        return zip(enumCaseCodingSettings, infferedRawValues).map { rawCodingSettingResult, infferedRawValue in 

            rawCodingSettingResult.flatMap { caseInfo, setting in

                switch setting {
                    case .none: 
                        if caseInfo.associatedValues.isEmpty {
                            return .success(.init(enumCaseInfo: caseInfo, payload: .rawValue(type: infferedRawValueType, value: infferedRawValue)))
                        } else if caseInfo.associatedValues.count == 1 {
                            return .success(.init(enumCaseInfo: caseInfo, payload: .content(.singleValue)))
                        } else {
                            return .success(.init(enumCaseInfo: caseInfo, payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues))))
                        }
                    case .some(.unkeyed(.rawValue(let type, let value), _)):
                        return .success(.init(enumCaseInfo: caseInfo, payload: .rawValue(type: type, value: value)))
                    case .some(.unkeyed(.content(.object(.none, _)), _)):
                        return .success(.init(enumCaseInfo: caseInfo, payload: .content(.object(inferingKeysFrom: caseInfo.associatedValues))))
                    case .some(.unkeyed(.content(let payloadContent), _)):
                        return .success(.init(enumCaseInfo: caseInfo, payload: .content(.init(payloadContent))))
                    case .some(.keyed(_, _, let rawSynax)): 
                        return .failure(.diagnostic(
                            node: rawSynax, 
                            message: .codingMacro.enumCodable.keyedSettingInUnkeyedEnumCoding()
                        ))
                }

            }

        }.apply(requireNoDuplicatedRawValues)

    }


    func validateSettingsForRawValueCoded(
        _ enumCaseCodingSettings: DiagnosticResultSequence<EnumCaseRawCodingSetting>
    ) -> DiagnosticResultSequence<EnumCaseRawCodingSetting> {

        return enumCaseCodingSettings.flatMapResult { caseInfo, setting in
            if setting != nil {
                .failure(.diagnostic(node: caseInfo.name, message: .codingMacro.enumCodable.unexpectedCustomizationInRawValueEnumCoding()))
            } else {
                .success((caseInfo, setting))
            }
        }

    }

}



extension EnumCodableMacro {

    private func requireNoDuplicatedKeys(
        in enumCaseCodingSpecs: DiagnosticResultSequence<KeyedCaseCodingSpec>
    ) -> DiagnosticResultSequence<KeyedCaseCodingSpec> {

        let keyDuplicationInfo = enumCaseCodingSpecs
            .reduce(into: [LiteralValue.ResolvedValue:[KeyedCaseCodingSpec]]()) { acc, specResult in
                if case .success(let spec) = specResult {
                    acc[spec.key.resolvedValue, default: []].append(spec)
                }
            }
            .values
            .filter { $0.count > 1 }
            .reduce(into: [KeyedCaseCodingSpec:[TokenSyntax]]()) { acc, conflictedSpecs in
                for (i, spec) in conflictedSpecs.enumerated() {
                    var otherSpecs = conflictedSpecs
                    otherSpecs.remove(at: i)
                    acc[spec, default: []].append(contentsOf: otherSpecs.map(\.enumCaseInfo.name))
                }
            }

        return enumCaseCodingSpecs.flatMapResult { spec in
            
            if let conflictedSpecCaseNames = keyDuplicationInfo[spec] {
                return .failure(.diagnostic(
                    node: spec.key.token, 
                    message: .codingMacro.enumCodable.duplicatedCaseKey(with: conflictedSpecCaseNames)
                ))
            } else {
                return .success(spec)
            }

        } 

    }


    private func requireNoDuplicatedRawValues(
        in enumCaseUnkeyedCodingSpecs: DiagnosticResultSequence<UnkeyedCaseCodingSpec>
    ) -> DiagnosticResultSequence<UnkeyedCaseCodingSpec> {

        let rawValueDuplicationInfo = enumCaseUnkeyedCodingSpecs
            .reduce(into: [String:[LiteralValue.ResolvedValue:[UnkeyedCaseCodingSpec]]]()) { acc, spec in 
                guard case .success(let spec) = spec else { return }
                guard case .rawValue(let type, let value) = spec.payload else { return }
                acc[type.trimmedDescription, default: [:]][value.resolvedValue, default: []].append(spec)
            }
            .values
            .flatMap(\.values)
            .filter { $0.count > 1 }
            .reduce(into: [UnkeyedCaseCodingSpec:[TokenSyntax]]()) { acc, conflictedSpecs in
                for (i, spec) in conflictedSpecs.enumerated() {
                    var otherSpecs = conflictedSpecs
                    otherSpecs.remove(at: i)
                    acc[spec, default: []].append(contentsOf: otherSpecs.map(\.enumCaseInfo.name))
                }
            }

        return enumCaseUnkeyedCodingSpecs.flatMapResult { spec in
            guard case .rawValue(_, let value) = spec.payload else { return .success(spec) }
            if let conflictedSpecCaseNames = rawValueDuplicationInfo[spec] {
                return .failure(.diagnostic(
                    node: context.isInSource(value.token) ? value.token : spec.enumCaseInfo.name, 
                    message: .codingMacro.enumCodable.duplicatedUnkeyedRawValuePayload(with: conflictedSpecCaseNames)
                ))
            } else {
                return .success(spec)
            }
        }

    }

}
