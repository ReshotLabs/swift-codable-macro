import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros



@main
struct CodableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableMacro.self,
        CodingFieldMacro.self,
        CodingIgnoreMacro.self
    ]
}
