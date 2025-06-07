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

        // extract user-defined custom coding setting for each enum case
        let enumCaseCodingSettings = try declGroup.enumCases.map { enumCase in 
            let enumCaseCodingMacroNodes = enumCase.attributes.filter { 
                ($0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text).flatMap(DecoratorMacros.init(rawValue:)) == .enumCaseCoding 
            }
            return (
                caseInfo: enumCase,
                setting: try EnumCaseCodingMacro.extractSetting(macroNodes: enumCaseCodingMacroNodes, context: context)
            )
        } as [EnumCaseRawCodingSetting]

        // basic validation of the settings 
        try validateSettings(enumCaseCodingSettings)

        // extract final enum case coding specifications 
        do {

            let generator: any Generator

            switch enumCodableOption {
                case .externalKeyed:
                    let caseCodingInfoList = try extractCodingSpecForExternalKeyed(enumCaseCodingSettings)
                    generator = ExternalKeyedGenerator(caseCodingInfoList: caseCodingInfoList)
                case .adjucentKeyed(let typeKey, let payloadKey):
                    guard typeKey.text != payloadKey.text else {
                        throw .diagnostic(node: macroNode.rawSyntax, message: .codingMacro.enumCodable.conflictedTypeAndPayloadKeys())
                    }
                    let caseCodingInfoList = try extractCodingSpecForAdjucentKeyed(enumCaseCodingSettings)
                    generator = AdjucentKeyedGenerator(caseCodingInfoList: caseCodingInfoList, typeKey: typeKey, payloadKey: payloadKey)
                case .internalKeyed(let typeKey):
                    let caseCodingInfoList = try extractCodingSpecForInternalKeyed(enumCaseCodingSettings, typeKey: typeKey)
                    generator = InternalKeyedGenerator(caseCodingInfoList: caseCodingInfoList, typeKey: typeKey)
                case .unkeyed:
                    let caseCodingInfoList = try extractCodingSpecForUnKeyed(enumCaseCodingSettings)
                    generator = UnkeyedGenerator(caseCodingInfoList: caseCodingInfoList)
                case .rawValueCoded:
                    try validateSettingsForRawValueCoded(enumCaseCodingSettings)
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

    fileprivate func validateSettings(_ settings: [EnumCaseRawCodingSetting]) throws(DiagnosticsError) {
        let diagnostics = settings.compactMap { rawSetting in
            validateSingleSetting(rawSetting.setting, onTarget: rawSetting.caseInfo)
        }
        guard diagnostics.isEmpty else {
            throw .diagnostics(diagnostics)
        }
    }


    private func validateSingleSetting(
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