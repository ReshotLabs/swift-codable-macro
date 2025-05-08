import SwiftSyntax


struct MacroInfo: Sendable, Equatable, Hashable {

    let name: TokenSyntax
    let arguments: [[LabeledExprSyntax]]

    let rawSyntax: AttributeSyntax

}


extension MacroInfo {

    static func extract(from macroNode: AttributeSyntax, parsingRules: [ArgumentsParsingRule] = []) throws -> Self {
        
        guard let name = macroNode.attributeName.as(IdentifierTypeSyntax.self)?.name else {
            throw .diagnostic(node: macroNode, message: .syntaxInfo.macroNode.missingMacroName())
        }
        let arguments = try macroNode.arguments?.grouped(with: parsingRules) ?? .init(repeating: [], count: parsingRules.count)

        return .init(
            name: name,
            arguments: arguments,
            rawSyntax: macroNode
        )

    }


    enum Error {
        static func missingMacroName() -> SyntaxInfoDiagnosticMessage {
            .init(id: "missing_macro_name", message: "Missing macro name")
        }
    }

}



extension SyntaxInfoDiagnosticMessageGroup {
    static var macroNode: MacroInfo.Error.Type {
        MacroInfo.Error.self
    }
}