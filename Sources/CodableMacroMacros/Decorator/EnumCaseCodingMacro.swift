import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct EnumCaseCodingMacro: CodingDecoratorMacro {

    enum EnumCaseCodingSetting: Equatable, Hashable {

        case keyedPayload(key: LiteralValue, payload: Payload?)
        case unkeyedPayload(PayloadContent)
        case unkeyedRawValue(type: ExprSyntax, value: LiteralValue)

        enum Payload: Hashable {
            case content(PayloadContent)
            case empty(EmptyPayloadOption)
        }

        enum PayloadContent: Equatable, Hashable {
            case singleValue, array, object(keys: [TokenSyntax], isInferred: Bool)
        }

        enum EmptyPayloadOption: Equatable, Hashable {
            case null, emptyObject, emptyArray, nothing
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


    static func processProperty(
        _ enumCaseInfo: EnumCaseInfo, 
        macroNodes: [AttributeSyntax],
        context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> EnumCaseCodingSetting? {

        guard macroNodes.count < 2 else {
            throw .diagnostic(node: enumCaseInfo.name, message: .decorator.general.duplicateMacro(name: "EnumCaseCoding"))
        }

        guard 
            let macroNode = macroNodes.first,
            let macroRawArguments = macroNode.arguments
        else {
            return nil
        }

        let macroArguments = try macroRawArguments.grouped(with: macroArgumentsParsingRule)
        
        return try extractSetting(from: macroArguments, enumCaseInfo: enumCaseInfo, context: context)

    }


    private static func extractSetting(
        from macroArguments: [[LabeledExprSyntax]], 
        enumCaseInfo: EnumCaseInfo,
        context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> EnumCaseCodingSetting? {

        if let rawValueArg = macroArguments[3].first {
            // @EnumCaseCoding(unKeyedRawValuePayload:type:)

            guard enumCaseInfo.associatedValues.isEmpty else {
                throw .diagnostic(
                    node: enumCaseInfo.name, 
                    message: .decorator.enumCaseCoding.rawValueSettingOnCaseWithAssociatedValues()
                )   
            }

            let type = try (macroArguments[4].first?.expression)
                .flatMap { typeExpr throws(DiagnosticsError) in 
                    if let memberAccessExpr = typeExpr.as(MemberAccessExprSyntax.self), memberAccessExpr.declName.baseName.trimmed.text == "self" {
                        // memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName
                        // return (memberAccessExpr.base?.is(DeclReferenceExprSyntax.self) == true) 
                        //     ? "\(raw: context.lexicalContext.map(\.trimmedDescription).joined(separator: ".")).\(memberAccessExpr.base)" 
                        //     : memberAccessExpr.base
                        memberAccessExpr.base
                    } else {
                        throw .diagnostic(
                            node: typeExpr, 
                            message: .decorator.general.notRawTypeExpr()
                        )
                    }
                }.orElse { () throws(DiagnosticsError) in 
                    if rawValueArg.expression.is(StringLiteralExprSyntax.self) {
                        "String"
                    } else if rawValueArg.expression.is(IntegerLiteralExprSyntax.self) {
                        "Int"
                    } else if rawValueArg.expression.is(FloatLiteralExprSyntax.self) {
                        "Double"
                    } else {
                        throw .diagnostic(
                            node: rawValueArg.expression, 
                            message: .decorator.general.notLiteral()
                        )
                    }
                }

            return try .unkeyedRawValue(type: type, value: .init(from: rawValueArg.expression))

        }

        if let unKeyedPayloadArg = macroArguments[5].first {
            // @EnumCaseCoding(unKeyedPayload:)

            guard !enumCaseInfo.associatedValues.isEmpty else {
                throw .diagnostic(
                    node: unKeyedPayloadArg.expression, 
                    message: .decorator.enumCaseCoding.unkeyedPayloadSettingOnCaseWithoutAssociatedValues()
                )
            }

            return try .unkeyedPayload(extractPayloadContentSetting(from: unKeyedPayloadArg, caseInfo: enumCaseInfo))

        }

        let keyArg = try macroArguments[0].first.flatMap { (keyArg) throws(DiagnosticsError) in
            if let key = keyArg.expression.as(MemberAccessExprSyntax.self), key.declName.baseName.trimmed.text == "auto" {
                return nil 
            } else if let key = try? LiteralValue(from: keyArg.expression), key.kind != .bool {
                return key
            } else {
                throw .diagnostic(node: keyArg.expression, message: .decorator.enumCaseCoding.unsupportedEnumCaseKey(keyArg.expression))
            }
        } as LiteralValue?

        let key = keyArg ?? .string(enumCaseInfo.name)

        if let emptyPayloadOptionArg = macroArguments[1].first {
            // @EnumCaseCoding(key:emptyPayloadOption:)

            guard let emptyPayloadOption = emptyPayloadOptionArg.expression.as(MemberAccessExprSyntax.self) else {
                throw .diagnostic(
                    node: emptyPayloadOptionArg.expression, 
                    message: .decorator.enumCaseCoding.unsupportedEmptyPayloadOption(emptyPayloadOptionArg.expression)
                )
            }

            guard enumCaseInfo.associatedValues.isEmpty else {
                throw .diagnostic(
                    node: emptyPayloadOptionArg.expression, 
                    message: .decorator.enumCaseCoding.emptyPayloadSettingOnCaseWithAssociatedValues()
                )
            }   

            return switch emptyPayloadOption.declName.baseName.trimmed.text {
                case "null": .keyedPayload(key: key, payload: .empty(.null))
                case "emptyObject": .keyedPayload(key: key, payload: .empty(.emptyObject))
                case "emptyArray": .keyedPayload(key: key, payload: .empty(.emptyArray))
                case "nothing": .keyedPayload(key: key, payload: .empty(.nothing))
                default: throw .diagnostic(
                    node: emptyPayloadOption, 
                    message: .decorator.enumCaseCoding.unsupportedEmptyPayloadOption(emptyPayloadOption)
                )
            }

        } else if let payloadArg = macroArguments[2].first {
            // @EnumCaseCoding(key:payload:)

            guard !enumCaseInfo.associatedValues.isEmpty else {
                throw .diagnostic(
                    node: payloadArg.expression, 
                    message: .decorator.enumCaseCoding.payloadContentSettingOnCaseWithoutAssociatedValue()
                )
            }

            return try .keyedPayload(key: key, payload: .content(extractPayloadContentSetting(from: payloadArg, caseInfo: enumCaseInfo)))

        } else if keyArg != nil {

            return .keyedPayload(key: key, payload: nil)

        } else {

            return nil  

        }

    }


    private static func extractPayloadContentSetting(
        from arg: LabeledExprSyntax, 
        caseInfo: EnumCaseInfo
    ) throws(DiagnosticsError) -> EnumCaseCodingSetting.PayloadContent {

        if let payloadFunctionCallExpr = arg.expression.as(FunctionCallExprSyntax.self) {

            let calledExpr = payloadFunctionCallExpr.calledExpression

            guard calledExpr.as(MemberAccessExprSyntax.self)?.declName.baseName.trimmed.text == "object" else {
                throw .diagnostic(
                    node: payloadFunctionCallExpr, 
                    message: .decorator.enumCaseCoding.unsupportedPayloadContent(payloadFunctionCallExpr)
                )
            }
            guard payloadFunctionCallExpr.arguments.count == caseInfo.associatedValues.count else {
                throw .diagnostic(
                    node: payloadFunctionCallExpr, 
                    message: .decorator.enumCaseCoding.mismatchedKeyCountForObjectPayload(
                        expected: caseInfo.associatedValues.count, 
                        actual: payloadFunctionCallExpr.arguments.count
                    )
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
            }
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

            return .object(keys: objectPayloadKeys, isInferred: false)

        } else if let payloadMemberAccessExpr = arg.expression.as(MemberAccessExprSyntax.self) {

            switch payloadMemberAccessExpr.declName.baseName.trimmed.text {
                case "singleValue": do {
                    guard caseInfo.associatedValues.count == 1 else {
                        throw .diagnostic(
                            node: payloadMemberAccessExpr, 
                            message: .decorator.enumCaseCoding.mismatchedAssociatedValueForSingleValuePayload()
                        )
                    }
                    return .singleValue
                }
                case "array": do {
                    return .array
                }
                case "object": do {
                    return .object(
                            keys: caseInfo.associatedValues.enumerated()
                                .map { i, associatedValue in associatedValue.label.map { "\($0)" } ?? "_\(raw: i)" },
                            isInferred: true
                        )
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

        static func rawValueSettingOnCaseWithAssociatedValues() -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "raw_value_setting_on_case_with_associated_values", message: "Raw value setting is not supported on cases with associated values")
        }

        static func unkeyedPayloadSettingOnCaseWithoutAssociatedValues() -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "unkeyed_payload_setting_on_case_without_associated_values", message: "Unkeyed payload setting is not supported on cases without associated values")
        }

        static func emptyPayloadSettingOnCaseWithAssociatedValues() -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "empty_payload_setting_on_case_with_associated_values", message: "Empty payload setting is not supported on cases with associated values")
        }

        static func payloadContentSettingOnCaseWithoutAssociatedValue() -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "payload_setting_on_case_without_associated_value", message: "Payload setting is not supported on cases without associated values")
        }

        static func mismatchedKeyCountForObjectPayload(expected: Int, actual: Int) -> CodingMacroImplBase.Error {
            .init(id: "mismatched_key_count_for_object_payload", message: "This case has \(expected) associatedValues, but \(actual) keys where specified for its object payload")
        }

        static func mismatchedAssociatedValueForSingleValuePayload() -> CodingDecoratorMacroDiagnosticMessage {
            .init(id: "mismatched_associated_value_for_single_value_payload", message: "Single value payload requires exactly one associated value")
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