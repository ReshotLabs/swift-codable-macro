//
//  CodingExpansionTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/24.
//

import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacroExpansion


#if canImport(CodableMacroMacros)
@testable import CodableMacroMacros

let testMacros: [String: MacroSpec] = [
    "Codable": .init(type: CodableMacro.self),
    "CodingField": .init(type: CodingFieldMacro.self),
    "CodingIgnore": .init(type: CodingIgnoreMacro.self),
    "EncodeTransform": .init(type: EncodeTransformMacro.self),
    "DecodeTransform": .init(type: DecodeTransformMacro.self),
    "CodingTransform": .init(type: CodingTransformMacro.self),
    "CodingValidate": .init(type: CodingValidateMacro.self),
    "SequenceCodingField": .init(type: SequenceCodingFieldMacro.self),
    "SingleValueCodable": .init(type: SingleValueCodableMacro.self),
    "SingleValueCodableDelegate": .init(type: SingleValueCodableDelegateMacro.self),
    "EnumCodable": .init(type: EnumCodableMacro.self),
    "EnumCaseCoding": .init(type: EnumCaseCodingMacro.self)
]
#endif



@Suite("Test Coding Expansion")
class CodingExpansionTest {
    
    func transformFunctionDefinition(indent: Int = 2) -> String {
    """
    func $__coding_transform<T, R>(_ value: T, _ transform: (T) throws -> R) throws -> R {
        return try transform(value)
    }
    """.replacingOccurrences(of: "\n", with: "\n" + String(repeating: " ", count: indent * 4))
    }
    
    func transformFunction(_ value: String, _ transform: String) -> String {
        "try $__coding_transform(\(value), \(transform))"
    }
    
    
    
    func validateFunctionDefinition(indent: Int = 2) -> String {
    #"""
    func $__coding_validate<T>(_ propertyName: String, _ validateExpr: String, _ value: T, _ validate: (T) throws -> Bool) throws {
        guard (try? validate(value)) == true else {
            throw CodingValidationError(type: "\(Self.self)", property: propertyName, validationExpr: validateExpr, value: "\(value as Any)")
        }
    }
    """#.replacingOccurrences(of: "\n", with: "\n" + String(repeating: " ", count: indent * 4))
    }
    
    func validateFunction(_ propertyName: String, _ validateExpr: String, _ value: String, _ validate: String) -> String {
        "try $__coding_validate(\(propertyName), \(validateExpr), \(value), \(validate))"
    }


    func makeEmptyArrayFunctionDefinition(indent: Int = 2) -> String {
        """
        func $__coding_make_empty_array<T>(ofType type: T.Type) -> [T] {
            return []
        }
        """.replacingOccurrences(of: "\n", with: "\n" + String(repeating: " ", count: indent * 4))
    }
    
    
    
    func containerCodingKeysName(path: [String]) -> String {
        "$__coding_container_keys_" + path.joined(separator: "_")
    }
    
    func containerVarName(path: [String]) -> String {
        "$__coding_container_" + path.joined(separator: "_")
    }
    
    
    
    func transformTypeInferenceFunctionName(_ transform: String) -> String {
        "codingTransformPassThroughWithTypeInference(\(transform))"
    }
    func typeExtractFunctionName(of value: String) -> String {
        "codableMacroStaticType(\(value))"
    }

    
}
