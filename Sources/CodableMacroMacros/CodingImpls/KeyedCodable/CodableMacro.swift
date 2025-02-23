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
    
    
    static func makeDecls(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let declGroupInfo = try DeclGroupSyntaxInfo.extract(from: declaration)
        
        let isClass = declGroupInfo.type == .class
        let isNonFinalClass = isClass && !declGroupInfo.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) })
        
        let (codingFieldInfoList, canAutoCodable) = try extractCodingFieldInfoList(from: declGroupInfo.properties)
        
        /// Whether an empty initializer should be created, only for class
        var shouldAutoInit: Bool {
            isClass
            && !declGroupInfo.properties.contains(where: \.isRequired)  // all stored properties are initialized or optional
            && !declGroupInfo.hasInitializer                            // has no initializer
        }
        
        // use the auto implementation provided by Swift Compiler if:
        // * no actual customization is found
        // * target is non-final class (where auto implementation will fail on extension)
        guard isNonFinalClass || !canAutoCodable else { return [] }
        
        guard !codingFieldInfoList.isEmpty else {
            // If the info list is still empty here, simply create an empty decode initializer
            // and an empty encode function
            return if shouldAutoInit {
                [
                    "init() {}",
                    "public required init(from decoder: Decoder) throws {}",
                    "public func encode(to encoder: Encoder) throws {}",
                ]
            } else {
                [
                    "public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws {}",
                    "public func encode(to encoder: Encoder) throws {}"
                ]
            }
        }
        
        // Analyse the stored properties and convert into a tree structure
        let structure = try CodingStructure.parse(codingFieldInfoList)
        
        // Convert the tree structure into actual "steps" for encoding and decoding
        let (operations, enumDecls) = try buildCodingSteps(
            from: structure,
            context: context,
            macroNode: node
        )
        
        var decls = [DeclSyntax]()
        
        decls += generateEnumDeclarations(from: enumDecls)
        decls += try generateDecodeInitializer(from: operations, isClass: isClass, context: context)
        decls.append(try generateEncodeMethod(from: operations, context: context))
        
        if shouldAutoInit {
            decls.append("init() {}")
        }
        
        return decls
        
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
        
    }
    
}


extension CodingMacroDiagnosticMessageGroup {
    static var codable: CodableMacro.Error.Type { CodableMacro.Error.self }
}
