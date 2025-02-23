import SwiftSyntax
import SwiftSyntaxMacros
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
    "SingleValueCodable": .init(type: SingleValueCodableMacro.self),
    "SingleValueCodableDelegate": .init(type: SingleValueCodableDelegateMacro.self),
]
#endif
