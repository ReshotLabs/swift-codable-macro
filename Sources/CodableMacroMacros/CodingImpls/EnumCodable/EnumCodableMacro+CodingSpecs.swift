import SwiftSyntax
import SwiftDiagnostics



extension EnumCodableMacro {

    struct EnumCaseKeyedCodingSpec: Equatable, Hashable {

        let enumCaseInfo: EnumCaseInfo
        let key: LiteralValue
        let payload: Payload

        enum Payload: Equatable, Hashable {
            case content(PayloadContent)
            case empty(EmptyPayloadOption)
        }

    }


    struct EnumCaseUnkeyedCodingSpec: Equatable, Hashable {

        let enumCaseInfo: EnumCaseInfo
        let payload: Payload

        enum Payload: Equatable, Hashable {
            case rawValue(type: ExprSyntax, value: LiteralValue)
            case content(PayloadContent)
        }

    }


    enum EmptyPayloadOption: Equatable, Hashable {
        case null, emptyObject, emptyArray, nothing
        init(from option: EnumCaseCodingMacro.EnumCaseCodingSetting.EmptyPayloadOption) {
            self = switch option {
                case .emptyArray: .emptyArray
                case .emptyObject: .emptyObject
                case .null: .null
                case .nothing: .nothing
            }
        }
    }


    enum PayloadContent: Equatable, Hashable {
        case singleValue, array, object(keys: [TokenSyntax])
        init(from option: EnumCaseCodingMacro.EnumCaseCodingSetting.PayloadContent) {
            self = switch option {
                case .singleValue: .singleValue
                case .array: .array
                case .object(let keys, _): .object(keys: keys)
            }
        }
    }


    enum EnumCodableOption: Sendable, CustomStringConvertible {

        case externalKeyed
        case adjucentKeyed(typeKey: TokenSyntax = "type", payloadKey: TokenSyntax = "payload")
        case internalKeyed(typeKey: TokenSyntax = "type")
        case unkeyed
        case rawValueCoded

        var description: String {
            switch self {
                case .externalKeyed: "externalKeyed"
                case .adjucentKeyed: "adjucentKeyed"
                case .internalKeyed: "internalKeyed"
                case .unkeyed: "unkeyed"
                case .rawValueCoded: "rawValueCoded"
            }
        }

        init(from expr: ExprSyntax) throws(DiagnosticsError) {

            if let memberAccessExpr = expr.as(MemberAccessExprSyntax.self) {

                switch memberAccessExpr.declName.baseName.trimmed.text {
                    case "externalKeyed": self = .externalKeyed
                    case "adjucentKeyed": self = .adjucentKeyed(typeKey: "type", payloadKey: "payload")
                    case "internalKeyed": self = .internalKeyed(typeKey: "type")
                    case "unkeyed": self = .unkeyed
                    case "rawValueCoded": self = .rawValueCoded
                    default: throw .diagnostic(
                        node: expr, 
                        message: .codingMacro.enumCodable.unsupportedEnumCodableOption(expr)
                    )
                }

            } else if let functionCallExpr = expr.as(FunctionCallExprSyntax.self) {

                switch functionCallExpr.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.trimmed.text {
                    case "adjucentKeyed": do {
                        let arguments = try functionCallExpr.arguments.grouped(
                            with: [.labeled("typeKey", canIgnore: true), .labeled("payloadKey", canIgnore: true)]
                        )
                        let typeKey = (arguments[0].first?.expression.as(StringLiteralExprSyntax.self)?.segments).map { "\($0)" as TokenSyntax }
                        let payloadKey = (arguments[1].first?.expression.as(StringLiteralExprSyntax.self)?.segments).map { "\($0)" as TokenSyntax }
                        self = .adjucentKeyed(typeKey: typeKey ?? "type", payloadKey: payloadKey ?? "payload")
                    }
                    case "internalKeyed": do {
                        let arguments = try functionCallExpr.arguments.grouped(with: [.labeled("typeKey", canIgnore: true)])
                        let typeKey = (arguments[0].first?.expression.as(StringLiteralExprSyntax.self)?.segments).map { "\($0)" as TokenSyntax }
                        self = .internalKeyed(typeKey: typeKey ?? "type")
                    }
                    default: throw .diagnostic(
                        node: expr, 
                        message: .codingMacro.enumCodable.unsupportedEnumCodableOption(expr)
                    )
                }

            } else {
                throw .diagnostic(
                    node: expr, 
                    message: .codingMacro.enumCodable.unsupportedEnumCodableOption(expr)
                )       
            }

        }

    }

}