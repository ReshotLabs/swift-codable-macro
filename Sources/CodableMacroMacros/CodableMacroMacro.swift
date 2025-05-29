import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros



@main
struct CodableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableMacro.self,
        CodingFieldMacro.self,
        CodingIgnoreMacro.self,
        DecodeTransformMacro.self,
        EncodeTransformMacro.self,
        CodingTransformMacro.self,
        CodingValidateMacro.self,
        SingleValueCodableMacro.self,
        SequenceCodingFieldMacro.self,
        SingleValueCodableDelegateMacro.self,
        EnumCodableMacro.self,
        EnumCaseCodingMacro.self
    ]
}



/// Represent all the properties decorator macros supported 
enum DecoratorMacros: String, Equatable, Hashable {
    
    case codingField = "CodingField"
    case codingIgnore = "CodingIgnore"
    case decodeTransform = "DecodeTransform"
    case encodeTransform = "EncodeTransform"
    case codingTransform = "CodingTransform"
    case codingValidate = "CodingValidate"
    case sequenceCodingField = "SequenceCodingField"
    case singleValueCodableDelegate = "SingleValueCodableDelegate"
    case enumCaseCoding = "EnumCaseCoding"
    
    var typeSyntax: TypeSyntax {
        .init(IdentifierTypeSyntax(name: "\(raw: rawValue)"))
    }
    
}
