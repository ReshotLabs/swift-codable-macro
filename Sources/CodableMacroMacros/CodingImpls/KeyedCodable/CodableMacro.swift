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



struct CodableMacro: CodingImplMacroProtocol {
    
    static let supportedAttachedTypes: Set<AttachedType> = [.class, .struct]
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("inherit", canIgnore: true)
    ]
    
    
    static func makeExtensionHeader(
        node: AttributeSyntax,
        type: some TypeSyntaxProtocol,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> SyntaxNodeString {
        
        let inherit = try extractInheritArgument(from: node.arguments)
        let comformanceClaude = (inherit ? "" : ": Codable") as SyntaxNodeString
        
        return "extension \(type)\(comformanceClaude)"
        
    }
    
    
    static func makeDecls(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let inherit = try extractInheritArgument(from: node.arguments)
        
        let declGroupInfo = try DeclGroupSyntaxInfo.extract(from: declaration)
        
        let isClass = declGroupInfo.type == .class
        let isNonFinalClass = isClass && !declGroupInfo.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) })
        
        let (codingFieldInfoList, canAutoCodable) = try extractCodingFieldInfoList(from: declGroupInfo.properties)
        
        /// Whether an empty initializer should be created, only for class
        var shouldAutoInit: Bool {
            isClass
            && !inherit                                                 // no inherited Codable
            && !declGroupInfo.properties.contains(where: \.isRequired)  // all stored properties are initialized or optional
            && !declGroupInfo.hasInitializer                            // has no initializer
        }
        
        // use the auto implementation provided by Swift Compiler if:
        // * no actual customization is found
        // * target is non-final class (where auto implementation will fail on extension)
        // * there is inherited Codable
        guard isNonFinalClass || inherit || !canAutoCodable else { return [] }
        
        guard !codingFieldInfoList.isEmpty else {
            // If the info list is still empty here, simply create an empty decode initializer
            // and an empty encode function
            return if shouldAutoInit {
                [
                    "init() {}",
                    """
                    public required init(from decoder: Decoder) throws {
                        \(raw: inherit ? "try super.init(from decoder)" : "")
                    }
                    """,
                    """
                    public \(raw: inherit ? "override " : "")func encode(to encoder: Encoder) throws {
                        \(raw: inherit ? "try super.encode(to encoder)" : "")
                    }
                    """,
                ]
            } else {
                [
                    """
                    public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws {
                        \(raw: inherit ? "try super.init(from decoder)" : "")
                    }
                    """,
                    """
                    public \(raw: inherit ? "override " : "")func encode(to encoder: Encoder) throws {
                        \(raw: inherit ? "try super.encode(to encoder)" : "")
                    }
                    """
                ]
            }
        }
        
        // Analyse the stored properties and convert into a tree structure
        let structure = try CodingStructure.parse(codingFieldInfoList)
        
        var decls = [DeclSyntax]()
        
        decls.append(contentsOf: try generateEnumDeclarations(from: structure, macroNode: node))
        decls.append(try generateDecodeInitializer(from: structure, isClass: isClass, inherit: inherit, macroNode: node))
        decls.append(try generateEncodeMethod(from: structure, inherit: inherit, macroNode: node))
        
        if shouldAutoInit {
            decls.append("init() {}")
        }
        
        return decls
        
    }
    
    
    static func extractInheritArgument(from arguments: AttributeSyntax.Arguments?) throws -> Bool {
        guard let arguments else { return false }
        let macroArguments = try arguments.grouped(with: macroArgumentsParsingRule)
        guard let inheritExpr = macroArguments[0].first?.expression else {
            return false
        }
        guard let inheritBoolLiteralExpr = inheritExpr.as(BooleanLiteralExprSyntax.self) else {
            throw .diagnostic(node: arguments, message: .codingMacro.codable.notBoolLiteralArgument)
        }
        return inheritBoolLiteralExpr.literal.tokenKind == .keyword(.true)
    }
    
}



extension CodableMacro {
        
    enum Error {
        
        static let noIdentifierFound: CodingMacroDiagnosticMessage = .init(
            id: "no_identifier",
            message: "The Codable macro can only be applied to class or struct declaration"
        )
        
        static let multipleCodingField: CodingMacroDiagnosticMessage = .init(
            id: "multiple_coding_field",
            message: "A stored property should have at most one CodingField macro"
        )
        
        static let unexpectedEmptyContainerStack: CodingMacroDiagnosticMessage = .init(
            id: "unexpected_empty_container_stack",
            message: "Internal Error: unexpected empty container stack"
        )
        
        static let missingDefaultOrOptional: CodingMacroDiagnosticMessage = .init(
            id: "missing_default_or_optional",
            message: "Internal Error: missing macro-level default or optional mark, which should have been filtered out"
        )
        
        static let notBoolLiteralArgument: CodingMacroDiagnosticMessage = .init(
            id: "not_bool_literal_argument",
            message: "The `inherit` argument support only boolean literal (true or false)"
        )
        
    }
    
}


extension CodingMacroDiagnosticMessageGroup {
    static var codable: CodableMacro.Error.Type { CodableMacro.Error.self }
}
