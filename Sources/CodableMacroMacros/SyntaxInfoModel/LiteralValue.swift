import SwiftSyntax
import SwiftDiagnostics



enum LiteralValue: Hashable, Sendable {

    case string(TokenSyntax)
    case int(TokenSyntax)
    case float(TokenSyntax)
    case bool(TokenSyntax)

    enum Kind {
        case string, int, float, bool
    }

    enum ResolvedValue: Hashable, Sendable {
        case string(String), number(Double), bool(Bool)
        var number: Double? { 
            switch self {
                case .number(let value): value
                default: nil
            }
        }
        var string: String? { 
            switch self {
                case .string(let value): value
                default: nil
            }
        }
        var bool: Bool? { 
            switch self {
                case .bool(let value): value
                default: nil
            }
        }
    }

    var token: TokenSyntax {
        switch self {
            case .string(let token), .float(let token), .int(let token), .bool(let token): token
        }
    }
    var completeExpr: ExprSyntax {
        switch self {
            case .string(let token): #""\#(token.trimmed)""#
            default: "\(token.trimmed)"
        }
    }
    var type: TypeSyntax {
        switch self {
            case .string: "String"
            case .int: "Int"
            case .float: "Double"
            case .bool: "Bool"
        }
    }
    var kind: Kind {
        switch self {
            case .string: .string
            case .int: .int
            case .float: .float
            case .bool: .bool
        }
    }
    var resolvedValue: ResolvedValue {
        switch self {
            case .string(let token): .string(token.trimmed.text)
            case .int(let token), .float(let token): .number(Double(token.trimmed.text) ?? 0)
            case .bool(let token): .bool(Bool(token.trimmed.text) ?? false)
        }
    }


    init(from literal: ExprSyntax) throws(DiagnosticsError) {

        if let value = literal.as(StringLiteralExprSyntax.self) {
            if value.segments.count == 1, case .stringSegment(let segment) = value.segments.first {
                self = .string(segment.content)
            } else {
                throw .diagnostic(node: value, message: .syntaxInfo.literalValue.notStaticStringLiteral())
            }
        } else if let value = literal.as(IntegerLiteralExprSyntax.self) {
            self = .int(value.literal)
        } else if let value = literal.as(FloatLiteralExprSyntax.self) {
            self = .float(value.literal)
        } else if let value = literal.as(BooleanLiteralExprSyntax.self) {
            self = .bool(value.literal)
        } else {
            throw .diagnostic(
                node: literal, 
                message: .syntaxInfo.literalValue.notLiteral()
            )
        }

    }


    enum Error {

        static func notLiteral() -> SyntaxInfoDiagnosticMessage {
            .init(id: "not_literal", message: "Expect a literal value")
        }

        static func notStaticStringLiteral() -> SyntaxInfoDiagnosticMessage {
            .init(id: "not_static_string_literal", message: "Expect a static string literal without interpolation")
        }

    }

}



extension SyntaxInfoDiagnosticMessageGroup {
    static var literalValue: LiteralValue.Error.Type {
        LiteralValue.Error.self
    }
}