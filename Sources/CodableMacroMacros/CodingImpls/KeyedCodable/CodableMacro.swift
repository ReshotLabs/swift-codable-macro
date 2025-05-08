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
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("inherit", canIgnore: true)
    ]


    let inherit: Bool

    /// Whether an empty initializer should be created, only for class
    var shouldAutoInit: Bool {
        declGroup.type == .class
        && !inherit                                                 // no inherited Codable
        && !declGroup.properties.contains(where: \.isRequired)  // all stored properties are initialized or optional
        && !declGroup.hasInitializer                            // has no initializer
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
        try super.init(macroNode: macroNode, declGroup: declGroup, context: context)
    }
    
    
    func makeExtensionHeader() throws -> SyntaxNodeString {
        let comformanceClaude = (inherit ? "" : ": Codable") as SyntaxNodeString
        return "extension \(declGroup.name.trimmed)\(comformanceClaude)"
    }
    
    
    func makeDecls() throws -> [DeclSyntax] {
        
        let isClass = declGroup.type == .class
        let isNonFinalClass = isClass && !declGroup.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) })
        
        let codingFieldInfoList = try extractCodingFieldInfoList()
        
        // MUST provide implementation instead of using that provided by Swift Compiler if any of the following is true:
        // * target is non-final class (where auto implementation will fail on extension)
        // * has inherited Codable
        // * has any customization
        guard isNonFinalClass || inherit || !canAutoCodable(codingFieldInfoList) else { return [] }

        let codingFieldInfoListWithoutIgnored = codingFieldInfoList.filter { !$0.isIgnored }
        
        guard !codingFieldInfoListWithoutIgnored.isEmpty else {
            // If the info list is still empty here, simply create an empty decode initializer
            // and an empty encode function
            return buildDeclSyntaxList {
                if shouldAutoInit {
                    "init() {}"
                }
                """
                public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws {
                    \(raw: inherit ? "try super.init(from decoder)" : "")
                }
                """
                """
                public \(raw: inherit ? "override " : "")func encode(to encoder: Encoder) throws {
                    \(raw: inherit ? "try super.encode(to encoder)" : "")
                }
                """
            }
        }
        
        // Analyse the stored properties and convert into a tree structure
        let structure = try CodingStructure.parse(codingFieldInfoListWithoutIgnored)
        
        return try buildDeclSyntaxList {
            try generateEnumDeclarations(from: structure)
            try generateDecodeInitializer(from: structure)
            try generateEncodeMethod(from: structure)
            if shouldAutoInit {
                "init() {}"
            }
        }
        
    }


    private func canAutoCodable(_ codingFieldInfoList: [CodingFieldInfo]) -> Bool {

        guard !codingFieldInfoList.isEmpty else {
            // an empty list means no customization, can auto-implement
            return true 
        }

        return !codingFieldInfoList.contains {
            $0.isIgnored                                                // has ignored property
            || $0.path.count > 1                                        // has custom path
            || $0.defaultValueOnMisMatch != nil                         // has custom mismatch default value
            || $0.defaultValueOnMissing != nil                          // has custom missing default value
            || $0.path.first != $0.propertyInfo.name.trimmed.text       // has custom path
            || $0.propertyInfo.initializer != nil                       // has initialized
            || $0.propertyInfo.hasOptionalTypeDecl                      // is optional type
            || !$0.validateExprs.isEmpty                                // has validation
            || $0.encodeTransform?.isEmpty == false                     // has encode transform
            || $0.decodeTransform?.transformExprs.isEmpty == false      // has decode transform
            || $0.sequenceCodingFieldInfo != nil                        // has sequence coding customization
        }

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
        
    }
    
}


extension CodingMacroImplBase.ErrorGroup {
    static var codable: CodableMacro.Error.Type { CodableMacro.Error.self }
}