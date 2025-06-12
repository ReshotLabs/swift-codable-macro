import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


final class EnumCodableMacro: CodingMacroImplBase, CodingMacroImplProtocol {

    static let supportedAttachedTypes: Set<AttachedType> = [.enum]
    static let supportedDecorators: Set<DecoratorMacros> = [.enumCaseCoding]
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


    func makeConformingProtocols() throws -> [TypeSyntax] {
        return ["EnumCodableProtocol"]
    }


    func makeDecls() throws -> [DeclSyntax] {

        guard !declGroup.enumCases.isEmpty else {
            throw .diagnostic(node: declGroup.name, message: .codingMacro.enumCodable.emptyEnum())
        }

        // extract user-defined custom coding setting for each enum case
        let enumCaseCodingSettings = declGroup.enumCases
            .map { enumCase in
                let enumCaseCodingMacroNodes = gatherSupportedDecorators(in: enumCase.attributes)[.enumCaseCoding, default: []]
                return captureDiagnostics { () throws(DiagnosticsError) in
                    try (enumCase, EnumCaseCodingMacro.extractSetting(from: enumCaseCodingMacroNodes, in: context))
                }
            }.apply(validateSettings) as DiagnosticResultSequence<EnumCaseRawCodingSetting>

        // extract final enum case coding specifications 
        do {

            let generator: any Generator

            switch enumCodableOption {
                case .externalKeyed:
                    let caseCodingSpecList = try extractCodingSpecForExternalKeyed(enumCaseCodingSettings).getResults()
                    generator = ExternalKeyedGenerator(caseCodingSpecList: caseCodingSpecList)
                case .adjucentKeyed(let typeKey, let payloadKey):
                    guard typeKey.text != payloadKey.text else {
                        throw .diagnostic(node: macroNode.rawSyntax, message: .codingMacro.enumCodable.conflictedCaseAndPayloadFieldName())
                    }
                    let caseCodingSpecList = try extractCodingSpecForAdjucentKeyed(enumCaseCodingSettings).getResults()
                    generator = AdjucentKeyedGenerator(caseCodingSpecList: caseCodingSpecList, typeKey: typeKey, payloadKey: payloadKey)
                case .internalKeyed(let typeKey):
                    let caseCodingSpecList = try extractCodingSpecForInternalKeyed(enumCaseCodingSettings, typeKey: typeKey).getResults()
                    generator = InternalKeyedGenerator(caseCodingSpecList: caseCodingSpecList, typeKey: typeKey)
                case .unkeyed:
                    let caseCodingSpecList = try extractCodingSpecForUnKeyed(enumCaseCodingSettings).getResults()
                    generator = UnkeyedGenerator(caseCodingSpecList: caseCodingSpecList)
                case .rawValueCoded:
                    _ = try validateSettingsForRawValueCoded(enumCaseCodingSettings).getResults()
                    generator = RawValueCodedGenerator()
            }

            return try buildDeclSyntaxList {
                try generator.generateCodingKeys()
                try generator.generateDecodeInitializer()
                try generator.generateEncodeMethod()
            }

        }

    }

}



extension EnumCodableMacro {

    fileprivate func validateSettings(
        _ rawSettings: DiagnosticResultSequence<EnumCaseRawCodingSetting>
    ) -> DiagnosticResultSequence<EnumCaseRawCodingSetting> {
        return rawSettings.flatMapResult { caseInfo, setting in
            if let diagnostic = validateSetting(setting, onTarget: caseInfo) {
                return .failure(.diagnostics([diagnostic]))
            } else {
                return .success((caseInfo, setting))
            } 
        }
    }


    private func validateSetting(
        _ setting: EnumCaseCodingMacro.EnumCaseCustomCodingSetting?, 
        onTarget caseInfo: EnumCaseInfo
    ) -> Diagnostic? {

        guard let setting else { return nil }

        switch setting {
            case .keyed(_, .empty(let emptyPayloadOption), _) where caseInfo.associatedValues.isNotEmpty:
                return .init(
                    node: emptyPayloadOption.rawSyntax, 
                    message: .codingMacro.enumCodable.emptyPayloadSettingOnCaseWithAssociatedValues()
                )
            case .keyed(_, .content(let payloadContent), _) where caseInfo.associatedValues.isEmpty:
                return .init(
                    node: payloadContent.rawSyntax, 
                    message: .codingMacro.enumCodable.payloadContentSettingOnCaseWithoutAssociatedValue()
                )
            case .keyed(_, .content(.singleValue(let rawSyntax)), _) where caseInfo.associatedValues.count != 1:
                return .init(
                    node: rawSyntax, 
                    message: .codingMacro.enumCodable.mismatchedAssociatedValueForSingleValuePayload()
                )
            case .unkeyed(.rawValue, let rawSyntax) where caseInfo.associatedValues.isNotEmpty:
                return .init(
                    node: rawSyntax, 
                    message: .codingMacro.enumCodable.rawValueSettingOnCaseWithAssociatedValues()
                )
            case .unkeyed(.content(let payloadContent), _) where caseInfo.associatedValues.isEmpty:
                return .init(
                    node: payloadContent.rawSyntax, 
                    message: .codingMacro.enumCodable.unkeyedPayloadSettingOnCaseWithoutAssociatedValues()
                )
            case .unkeyed(.content(.singleValue(let rawSyntax)), _) where caseInfo.associatedValues.count != 1:
                return .init(
                    node: rawSyntax, 
                    message: .codingMacro.enumCodable.mismatchedAssociatedValueForSingleValuePayload()
                )
            case let .keyed(_, .content(.object(keys, rawSynax)), _), let .unkeyed(.content(.object(keys, rawSynax)), _):
                guard let keys else { fallthrough }
                guard keys.count == caseInfo.associatedValues.count else {
                    return .init(
                        node: rawSynax, 
                        message: .codingMacro.enumCodable.mismatchedKeyCountForObjectPayload(
                            expected: caseInfo.associatedValues.count, 
                            actual: keys.count
                        )
                    )
                }
                fallthrough
            default:
                return nil 
        }

    }

}
