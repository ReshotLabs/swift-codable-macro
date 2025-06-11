import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct EnumCaseCodingMacro: CodingDecoratorMacro {

    enum EnumCaseCustomCodingSetting: Hashable {

        case keyed(key: LiteralValue?, payload: Payload?, rawSyntax: AttributeSyntax.Arguments)
        case unkeyed(UnkeyedPayload, rawSyntax: AttributeSyntax.Arguments)

        enum Payload: Hashable {
            case content(PayloadContent)
            case empty(EmptyPayloadOption)
            var rawSyntax: ExprSyntax {
                switch self {
                    case .content(let content): content.rawSyntax
                    case .empty(let emptyOption): emptyOption.rawSyntax
                }
            }
        }

        enum PayloadContent: Hashable {
            case singleValue(rawSyntax: ExprSyntax), array(rawSyntax: ExprSyntax), object(keys: [TokenSyntax]?, rawSyntax: ExprSyntax)
            var rawSyntax: ExprSyntax {
                switch self {
                    case .singleValue(let rawSyntax), .array(let rawSyntax), .object(_, let rawSyntax): rawSyntax
                }
            }
        }

        enum EmptyPayloadOption: Hashable {
            case null(rawSyntax: ExprSyntax), emptyObject(rawSyntax: ExprSyntax), emptyArray(rawSyntax: ExprSyntax), nothing(rawSyntax: ExprSyntax)
            var rawSyntax: ExprSyntax {
                switch self {
                    case .null(let rawSyntax), .emptyObject(let rawSyntax), .emptyArray(let rawSyntax), .nothing(let rawSyntax): rawSyntax
                }
            }
        }

        enum UnkeyedPayload: Hashable {
            case rawValue(type: ExprSyntax, value: LiteralValue)
            case content(PayloadContent)
        }

    }


    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("key", canIgnore: true),
        .labeled("emptyPayloadOption", canIgnore: true),
        .labeled("payload", canIgnore: true),
        .labeled("unkeyedRawValuePayload", canIgnore: true),
        .labeled("type", canIgnore: true),
        .labeled("unkeyedPayload", canIgnore: true),
    ]


    static func extractSetting(
        from macroNodes: [AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> EnumCaseCustomCodingSetting? {
        guard macroNodes.count < 2 else {
            let dianostics = macroNodes.map { Diagnostic(node: $0, message: .decorator.general.duplicateMacro(name: "EnumCaseCoding")) }
            throw .diagnostics(dianostics)
        }
        guard let macroNode = macroNodes.first else { return nil }
        guard let macroRawArguments = macroNode.arguments else { return nil }
        return try extractSetting(from: macroRawArguments)
    }


    private static func extractSetting(from macroRawArguments: AttributeSyntax.Arguments) throws(DiagnosticsError) -> EnumCaseCustomCodingSetting? {

        let macroArguments = try macroRawArguments.grouped(with: macroArgumentsParsingRule)

        if let rawValueArg = macroArguments[3].first {
            // @EnumCaseCoding(unKeyedRawValuePayload:type:)

            let rawValueLiteral = try LiteralValue(from: rawValueArg.expression)

            let type = try (macroArguments[4].first?.expression)
                .flatMap { typeExpr throws(DiagnosticsError) in 
                    if let memberAccessExpr = typeExpr.as(MemberAccessExprSyntax.self), memberAccessExpr.declName.baseName.trimmed.text == "self" {
                        memberAccessExpr.base
                    } else {
                        throw .diagnostic(
                            node: typeExpr, 
                            message: .codingMacro.enumCodable.unkeyedRawValueTypeNotTypeIdentifierSyntax()
                        )
                    }
                }.orElse {
                    .init(TypeExprSyntax(type: rawValueLiteral.type))
                }

            return .unkeyed(.rawValue(type: type, value: rawValueLiteral), rawSyntax: macroRawArguments)

        }

        if let unKeyedPayloadArg = macroArguments[5].first {
            // @EnumCaseCoding(unKeyedPayload:)

            return try .unkeyed(.content(extractPayloadContentSetting(from: unKeyedPayloadArg)), rawSyntax: macroRawArguments)

        }

        let key = try macroArguments[0].first.flatMap { (keyArg) throws(DiagnosticsError) in
            if let key = keyArg.expression.as(MemberAccessExprSyntax.self), key.declName.baseName.trimmed.text == "auto" {
                return nil 
            } else if let key = try? LiteralValue(from: keyArg.expression), key.kind != .bool {
                return key
            } else {
                throw .diagnostic(node: keyArg.expression, message: .decorator.enumCaseCoding.unsupportedEnumCaseKey(keyArg.expression))
            }
        } as LiteralValue?

        if let emptyPayloadOptionArg = macroArguments[1].first {
            // @EnumCaseCoding(key:emptyPayloadOption:)

            guard let emptyPayloadOption = emptyPayloadOptionArg.expression.as(MemberAccessExprSyntax.self) else {
                throw .diagnostic(
                    node: emptyPayloadOptionArg.expression, 
                    message: .decorator.enumCaseCoding.unsupportedEmptyPayloadOption(emptyPayloadOptionArg.expression)
                )
            }  

            return switch emptyPayloadOption.declName.baseName.trimmed.text {
                case "null": .keyed(key: key, payload: .empty(.null(rawSyntax: .init(emptyPayloadOption))), rawSyntax: macroRawArguments)
                case "emptyObject": .keyed(key: key, payload: .empty(.emptyObject(rawSyntax: .init(emptyPayloadOption))), rawSyntax: macroRawArguments)
                case "emptyArray": .keyed(key: key, payload: .empty(.emptyArray(rawSyntax: .init(emptyPayloadOption))), rawSyntax: macroRawArguments)
                case "nothing": .keyed(key: key, payload: .empty(.nothing(rawSyntax: .init(emptyPayloadOption))), rawSyntax: macroRawArguments)
                default: throw .diagnostic(
                    node: emptyPayloadOption, 
                    message: .decorator.enumCaseCoding.unsupportedEmptyPayloadOption(emptyPayloadOption)
                )
            }

        } else if let payloadArg = macroArguments[2].first {
            // @EnumCaseCoding(key:payload:)

            return try .keyed(key: key, payload: .content(extractPayloadContentSetting(from: payloadArg)), rawSyntax: macroRawArguments)

        } else if key != nil {

            return .keyed(key: key, payload: nil, rawSyntax: macroRawArguments)

        } else {

            return nil  

        }

    }


    private static func extractPayloadContentSetting(
        from arg: LabeledExprSyntax
    ) throws(DiagnosticsError) -> EnumCaseCustomCodingSetting.PayloadContent {

        if let payloadFunctionCallExpr = arg.expression.as(FunctionCallExprSyntax.self) {

            let calledExpr = payloadFunctionCallExpr.calledExpression

            guard calledExpr.as(MemberAccessExprSyntax.self)?.declName.baseName.trimmed.text == "object" else {
                throw .diagnostic(
                    node: payloadFunctionCallExpr, 
                    message: .decorator.enumCaseCoding.unsupportedPayloadContent(payloadFunctionCallExpr)
                )
            }

            let objectPayloadKeys = try payloadFunctionCallExpr.arguments.map { arg throws(DiagnosticsError) in 
                let key = arg.expression.as(StringLiteralExprSyntax.self)?.segments.first
                guard let key, case .stringSegment(let segment) = key else {
                    throw .diagnostic(
                        node: arg.expression, 
                        message: .decorator.enumCaseCoding.notStringLiteralObjectPayloadKey()
                    )
                }
                return segment.content
            } as [TokenSyntax]

            let objectPayloadKeyStrs = objectPayloadKeys.map(\.trimmed.text)
            let duplicatedKeyStrs = Dictionary(
                zip(objectPayloadKeyStrs, [Int](repeating: 1, count: objectPayloadKeyStrs.count)), 
                uniquingKeysWith: { $0 + $1 }
            ).filter { $0.value > 1 }.keys

            guard duplicatedKeyStrs.isEmpty else {
                throw .diagnostic(
                    node: payloadFunctionCallExpr.arguments, 
                    message: .decorator.enumCaseCoding.duplicatedObjectPayloadKeys(duplicatedKeyStrs)
                )
            }

            return .object(keys: objectPayloadKeys, rawSyntax: .init(payloadFunctionCallExpr))

        } else if let payloadMemberAccessExpr = arg.expression.as(MemberAccessExprSyntax.self) {

            switch payloadMemberAccessExpr.declName.baseName.trimmed.text {
                case "singleValue": do {
                    return .singleValue(rawSyntax: .init(payloadMemberAccessExpr))
                }
                case "array": do {
                    return .array(rawSyntax: .init(payloadMemberAccessExpr))
                }
                case "object": do {
                    return .object(keys: nil, rawSyntax: .init(payloadMemberAccessExpr))
                }
                default: do {
                    throw .diagnostic(
                        node: payloadMemberAccessExpr, 
                        message: .decorator.enumCaseCoding.unsupportedPayloadContent(payloadMemberAccessExpr)
                    )
                }
            }

        } else {

            throw .diagnostic(
                node: arg.expression, 
                message: .decorator.enumCaseCoding.unsupportedPayloadContent(arg.expression)
            )

        }

    }


    enum Error {

        static func unsupportedEmptyPayloadOption(_ option: some ExprSyntaxProtocol) -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "unsupported_matching_option", message: "specified matching option \(option.trimmed) is not supported")
        }

        static func unsupportedPayloadContent(_ option: some ExprSyntaxProtocol) -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "unsupported_retrieving_content", message: "specified retrieving option \(option.trimmed) is not supported")
        }

        static func unsupportedEnumCaseKey(_ key: some ExprSyntaxProtocol) -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "unsupported_enum_case_key", message: "specified enum case key \(key.trimmed) is not supported")
        }

        static func duplicatedObjectPayloadKeys(_ keys: some Collection<String>) -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "duplicated_object_payload_keys", message: "Object payload keys \(keys.joined(separator: ", ")) has duplication")
        }

        static func notStringLiteralObjectPayloadKey() -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "not_string_literal_object_payload_key", message: "Expect object payload key to be a string literal")
        }

    }

}


extension CodingDecoratorMacroDiagnosticMessageGroup {

    static var enumCaseCoding: EnumCaseCodingMacro.Error.Type {
        EnumCaseCodingMacro.Error.self
    }

}