//
//  CodableMacro.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/7.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



final class CodableMacro: CodingMacroImplBase, CodingMacroImplProtocol {

    static let supportedAttachedTypes: Set<AttachedType> = [.class, .struct]
    static let supportedDecorators: Set<DecoratorMacros> = [
        .codingField, .codingIgnore, .codingTransform, .decodeTransform, .encodeTransform, .codingValidate, .sequenceCodingField
    ]

    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("inherit", canIgnore: true),
        .labeled("keyDecodingStrategy", canIgnore: true),
        .labeled("verbose", canIgnore: true)
    ]

    enum KeyDecodingStrategy {
        case useDefaultKeys
        case convertFromSnakeCase

        static func parse(from expr: ExprSyntax) -> KeyDecodingStrategy? {
            if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
                switch memberAccess.declName.baseName.text {
                case "useDefaultKeys":
                    return .useDefaultKeys
                case "convertFromSnakeCase":
                    return .convertFromSnakeCase
                default:
                    return nil
                }
            }
            return nil
        }
    }

    let inherit: Bool
    let keyDecodingStrategy: KeyDecodingStrategy
    let verbose: Bool

    /// Whether an empty initializer should be created, only for class
    var shouldAutoInit: Bool {
        declGroup.type == .class
        && !inherit                                                 // no inherited Codable
        && !declGroup.properties.contains(where: \.isRequired)      // all stored properties are initialized or optional
        && !declGroup.hasInitializer                                // has no initializer
    }


    required init(macroNode: MacroInfo, declGroup: DeclGroupSyntaxInfo, context: any MacroExpansionContext) throws {
        if let inheritExpr = macroNode.arguments[0].first?.expression {
            guard let inheritBoolLiteralExpr = inheritExpr.as(BooleanLiteralExprSyntax.self) else {
                throw .diagnostic(node: inheritExpr, message: .codingMacro.singleValueCodable.notBoolLiteralArgument)
            }
            inherit = inheritBoolLiteralExpr.literal.tokenKind == .keyword(.true)
            if inherit && declGroup.type != .class {
                throw .diagnostic(node: inheritExpr, message: .codingMacro.singleValueCodable.valueTypeInherit)
            }
        } else {
            inherit = false
        }

        if let keyDecodingStrategyExpr = macroNode.arguments[1].first?.expression {
            if let strategy = KeyDecodingStrategy.parse(from: keyDecodingStrategyExpr) {
                keyDecodingStrategy = strategy
            } else {
                throw .diagnostic(node: keyDecodingStrategyExpr, message: .codingMacro.codable.invalidKeyDecodingStrategy)
            }
        } else {
            keyDecodingStrategy = .useDefaultKeys
        }

        if let verboseExpr = macroNode.arguments[2].first?.expression {
            guard let verboseBoolLiteralExpr = verboseExpr.as(BooleanLiteralExprSyntax.self) else {
                throw .diagnostic(node: verboseExpr, message: .codingMacro.codable.notBoolLiteralArgument)
            }
            verbose = verboseBoolLiteralExpr.literal.tokenKind == .keyword(.true)
        } else {
            verbose = false
        }

        try super.init(macroNode: macroNode, declGroup: declGroup, context: context)
    }

    func makeConformingProtocols() throws -> [TypeSyntax] {
        return inherit ? [] : ["Codable"]
    }


    func makeDecls() throws -> [DeclSyntax] {

        log("🚀 Starting Codable macro expansion for \(declGroup.name)")
        log("📋 Configuration: inherit=\(inherit), keyDecodingStrategy=\(keyDecodingStrategy), verbose=\(verbose)")

        let isClass = declGroup.type == .class
        let isNonFinalClass = isClass && !declGroup.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) })

        log("🏗️  Type info: isClass=\(isClass), isNonFinalClass=\(isNonFinalClass)")

        let propertyCodingSpecList = try extractPropertyCodingSpecList()

        log("📊 Found \(propertyCodingSpecList.count) properties to process")
        for (index, spec) in propertyCodingSpecList.enumerated() {
            log("   \(index + 1). Property '\(spec.propertyInfo.nameStr)' -> path: \(spec.path)")
        }

        // MUST provide implementation instead of using that provided by Swift Compiler if any of the following is true:
        // * target is non-final class (where auto implementation will fail on extension)
        // * has inherited Codable
        // * has any customization
        let needsCustomImplementation = isNonFinalClass || inherit || !canAutoCodable(propertyCodingSpecList)
        log("🔍 Needs custom implementation: \(needsCustomImplementation)")

        guard needsCustomImplementation else {
            log("✅ Using Swift compiler auto-implementation")
            return []
        }

        let propertyCodingSpecListWithoutIgnored = propertyCodingSpecList.filter { !$0.isIgnored }

        let ignoredCount = propertyCodingSpecList.count - propertyCodingSpecListWithoutIgnored.count
        if ignoredCount > 0 {
            log("🚫 Ignored \(ignoredCount) properties")
        }

        guard !propertyCodingSpecListWithoutIgnored.isEmpty else {
            log("📝 Generating empty Codable implementation (no properties to encode/decode)")
            // If the spec list is still empty here, simply create an empty decode initializer
            // and an empty encode function
            return buildDeclSyntaxList {
                if shouldAutoInit {
                    "init() {}"
                }
                """
                public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws {
                    \(raw: inherit ? "try super.init(from: decoder)" : "")
                }
                """
                """
                public \(raw: inherit ? "override " : "")func encode(to encoder: Encoder) throws {
                    \(raw: inherit ? "try super.encode(to: encoder)" : "")
                }
                """
            }
        }

        log("🌳 Analyzing property structure for code generation")
        // Analyse the stored properties and convert into a tree structure
        let structure = try CodingStructure.parse(propertyCodingSpecListWithoutIgnored)

        log("🔧 Generating Codable implementation")
        log("   - CodingKeys enums")
        log("   - init(from decoder:) method")
        log("   - encode(to encoder:) method")
        if shouldAutoInit {
            log("   - empty init() method")
        }

        return try buildDeclSyntaxList {
            try generateEnumDeclarations(from: structure)
            try generateDecodeInitializer(from: structure)
            try generateEncodeMethod(from: structure)
            if shouldAutoInit {
                "init() {}"
            }
        }

    }


    /// Transform property name according to the keyDecodingStrategy
    func transformPropertyName(_ propertyName: String) -> String {
        let transformedName = switch keyDecodingStrategy {
        case .useDefaultKeys:
            propertyName
        case .convertFromSnakeCase:
            propertyName.convertToSnakeCase()
        }

        log("🔄 Property '\(propertyName)' transformed to key '\(transformedName)' using strategy \(keyDecodingStrategy)")

        return transformedName
    }

    /// Log a message if verbose mode is enabled
    private func log(_ message: String) {
        guard verbose else { return }

        print(message)
        // In macro expansion, we can emit notes/warnings to provide logging
        // This will appear in the build output when the macro is expanded
        context.diagnose(.init(
            node: macroNode.rawSyntax,
            message: VerboseLogMessage(message: message)
        ))
    }

    private func canAutoCodable(_ codingFieldInfoList: [PropertyCodingSpec]) -> Bool {

        guard !codingFieldInfoList.isEmpty else {
            // an empty list means no customization, can auto-implement
            log("✅ Can use auto-codable: no properties found")
            return true
        }

        // If we're using a key decoding strategy other than default, we need custom implementation
        if keyDecodingStrategy != .useDefaultKeys {
            log("❌ Cannot use auto-codable: custom keyDecodingStrategy requires custom implementation")
            return false
        }

        let needsCustom = codingFieldInfoList.contains {
            if $0.isIgnored {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' is ignored")
                return true
            }
            if $0.path.count > 1 {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has nested path \($0.path)")
                return true
            }
            if $0.defaultValueOnMisMatch != nil {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has onMismatch default value")
                return true
            }
            if $0.defaultValueOnMissing != nil {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has onMissing default value")
                return true
            }
            if $0.path.first != $0.propertyInfo.name.trimmed.text {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has custom key '\($0.path.first ?? "")'")
                return true
            }
            if $0.propertyInfo.initializer != nil {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has initializer")
                return true
            }
            if $0.propertyInfo.hasOptionalTypeDecl {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' is optional")
                return true
            }
            if !$0.validateExprs.isEmpty {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has validation")
                return true
            }
            if $0.encodeTransform?.isEmpty == false {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has encode transform")
                return true
            }
            if $0.decodeTransform?.transformExprs.isEmpty == false {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has decode transform")
                return true
            }
            if $0.sequenceCodingFieldInfo != nil {
                log("❌ Cannot use auto-codable: property '\($0.propertyInfo.nameStr)' has sequence coding customization")
                return true
            }
            return false
        }

        if !needsCustom {
            log("✅ Can use auto-codable: no customizations detected")
        }

        return !needsCustom

    }

}



extension CodableMacro {

    enum Error {

        static let noIdentifierFound: CodingMacroImplBase.Error = .init(
            id: "no_identifier",
            message: "The Codable macro can only be applied to class or struct declaration"
        )

        static let multipleCodingField: CodingMacroImplBase.Error = .init(
            id: "multiple_coding_field",
            message: "A stored property should have at most one CodingField macro"
        )

        static let missingDefaultOrOptional: CodingMacroImplBase.Error = .init(
            id: "missing_default_or_optional",
            message: "Internal Error: missing macro-level default or optional mark, which should have been filtered out"
        )

        static let notBoolLiteralArgument: CodingMacroImplBase.Error = .init(
            id: "not_bool_literal_argument",
            message: "The `inherit` argument support only boolean literal (true or false)"
        )

        static let codingCustomizationOnNonStoredProperty: CodingMacroImplBase.Error = .init(
            id: "coding_customization_on_non_stored_property",
            message: "Coding customization can only be applied to stored properties"
        )

        static let propertyCannotBeIgnored: CodingMacroImplBase.Error = .init(
            id: "property_cannot_be_ignored",
            message: "Property can only be ignored if it is optional or has a default value."
        )

        static let defaultValueOnConstantwithInitializer: CodingMacroImplBase.Error = .init(
            id: "default_value_on_constant_with_initializer",
            message: "Default value on constant property with initializer is not allowed."
        )

        static let invalidKeyDecodingStrategy: CodingMacroImplBase.Error = .init(
            id: "invalid_key_decoding_strategy",
            message: "Invalid keyDecodingStrategy. Supported values are .useDefaultKeys and .convertFromSnakeCase"
        )

    }

}

/// Diagnostic message for verbose logging
struct VerboseLogMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: SwiftDiagnostics.MessageID = .init(domain: "CodableMacro", id: "verbose_log")
    let severity: SwiftDiagnostics.DiagnosticSeverity = .note
}

extension CodingMacroImplBase.ErrorGroup {
    static var codable: CodableMacro.Error.Type { CodableMacro.Error.self }
}
