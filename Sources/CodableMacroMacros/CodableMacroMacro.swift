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
    ]
}



/// Represent all the properties decorator macros supported 
enum DecoratorMacros: String, Equatable, Hashable {
    
    case codingField = "CodingField"
    case codingIgnore = "CodingIgnore"
    case decodeTransform = "DecodeTransform"
    case encodeTransform = "EncodeTransform"
    
    var typeSyntax: TypeSyntax {
        .init(IdentifierTypeSyntax(name: "\(raw: rawValue)"))
    }
    
}
