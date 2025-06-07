import SwiftSyntax
import SwiftSyntaxBuilder



extension EnumCodableMacro {

    struct RawValueCodedGenerator: Generator {}

}



extension EnumCodableMacro.RawValueCodedGenerator {

    func generateCodingKeys() throws -> [DeclSyntax] {
        return []
    }


    func generateDecodeInitializer() throws -> InitializerDeclSyntax {
        return try .init("public init(from decoder: Decoder) throws") {
            "let rawValue = try Self.RawValue(from: decoder)"
            try GuardStmtSyntax("guard let value = Self(rawValue: rawValue) as Self? else") {
                noMatchCaseFoundFallbackStatements
            }
            "self = value"
        }
    }


    func generateEncodeMethod() throws -> FunctionDeclSyntax {
        return try .init("public func encode(to encoder: Encoder) throws") {
            "try self.rawValue.encode(to: encoder)"
        }
    }

}