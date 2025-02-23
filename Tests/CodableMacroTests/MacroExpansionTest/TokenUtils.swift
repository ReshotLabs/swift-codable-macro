//
//  TokenUtils.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/20.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion


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
        let valid = (try? validate(value)) ?? false
        guard valid else {
            throw CodingValidationError(
                type: "\(Self.self)",
                property: propertyName,
                validationExpr: validateExpr,
                value: "\(value as Any)"
            )
        }
    }
    """#.replacingOccurrences(of: "\n", with: "\n" + String(repeating: " ", count: indent * 4))
}

func validateFunction(_ propertyName: String, _ validateExpr: String, _ value: String, _ validate: String) -> String {
    "try $__coding_validate(\(propertyName), \(validateExpr), \(value), \(validate))"
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
