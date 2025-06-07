import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder



extension EnumCodableMacro {

    typealias EnumCaseRawCodingSetting = (caseInfo: EnumCaseInfo, setting: EnumCaseCodingMacro.EnumCaseCustomCodingSetting?)


    struct KeyedCaseCodingSpec: Equatable, Hashable {
        let enumCaseInfo: EnumCaseInfo
        let key: LiteralValue
        let payload: Payload
    }


    struct UnkeyedCaseCodingSpec: Equatable, Hashable {
        let enumCaseInfo: EnumCaseInfo
        let payload: UnkeyedPayload
    }


    enum Payload: Hashable {
        case content(PayloadContent)
        case empty(EmptyPayloadOption)
        init(_ setting: EnumCaseCodingMacro.EnumCaseCustomCodingSetting.Payload) {
            switch setting {
                case .content(let content): self = .content(.init(content))
                case .empty(let option): self = .empty(.init(option))
            }
        }
        static func empty(_ option: EnumCaseCodingMacro.EnumCaseCustomCodingSetting.EmptyPayloadOption) -> Payload {
            .empty(.init(option))
        }
        static func content(_ content: EnumCaseCodingMacro.EnumCaseCustomCodingSetting.PayloadContent) -> Payload {
            .content(.init(content))
        }
    }


    enum PayloadContent: Hashable {
        case singleValue, array, object(keys: [ObjectPayloadKey])
        init(_ setting: EnumCaseCodingMacro.EnumCaseCustomCodingSetting.PayloadContent) {
            switch setting {
                case .singleValue: self = .singleValue
                case .array: self = .array
                case .object(let keys, _): 
                    if let keys {
                        self = .object(keys: keys.map { .named($0) })
                    } else {
                        fatalError("Internal Error: object payload keys are expected to be filled at this point")
                    }
            }
        }
        static func object(inferingKeysFrom associatedValues: [EnumCaseInfo.AssociatedValue]) -> PayloadContent {
            .object(keys: ObjectPayloadKey.infer(from: associatedValues))
        }
    }


    enum EmptyPayloadOption: Hashable {
        case null, emptyObject, emptyArray, nothing
        init(_ setting: EnumCaseCodingMacro.EnumCaseCustomCodingSetting.EmptyPayloadOption) {
            switch setting {
                case .null: self = .null
                case .emptyObject: self = .emptyObject
                case .emptyArray: self = .emptyArray
                case .nothing: self = .nothing
            }
        }
    }


    enum UnkeyedPayload: Hashable {
        case rawValue(type: ExprSyntax, value: LiteralValue)
        case content(PayloadContent)
        init(_ setting: EnumCaseCodingMacro.EnumCaseCustomCodingSetting.UnkeyedPayload) {
            switch setting {
                case .rawValue(let type, let value): self = .rawValue(type: type, value: value)
                case .content(let content): self = .content(.init(content))
            }
        }
        static func content(_ content: EnumCaseCodingMacro.EnumCaseCustomCodingSetting.PayloadContent) -> UnkeyedPayload {
            .content(.init(content))
        }
        static func rawValue(_ type: ExprSyntax, _ value: LiteralValue) -> UnkeyedPayload {
            .rawValue(type: type, value: value)
        }
    }


    enum ObjectPayloadKey: ExprSyntaxProtocol, ExpressibleByStringLiteral, Hashable {

        case named(TokenSyntax)
        case indexed(IndexedToken)

        var text: String {
            switch self {
                case .named(let token): return token.text
                case .indexed(let index): return index.token.text
            }
        }

        var _syntaxNode: SwiftSyntax.Syntax {
            switch self {
                case .named(let name): return .init(name)
                case .indexed(let index): return .init(index.token)
            }
        }

        init?(_ node: __shared some SyntaxProtocol) { 
            if let token = node.as(TokenSyntax.self) {
                self = .named(token)
            } else {
                return nil 
            }
        }

        init(stringLiteral value: String) {
            self = .named(.init(stringLiteral: value))
        }

        static var structure: SyntaxNodeStructure {
            .layout([])
        }

        static func indexed(_ index: Int) -> ObjectPayloadKey {
            .indexed(.init(index: index))
        }

        static func infer(from associatedValues: [EnumCaseInfo.AssociatedValue]) -> [ObjectPayloadKey] {
            associatedValues.enumerated().map { i, associatedValue in
                associatedValue.label.map { .named($0) } ?? .indexed(i)
            }
        }

        struct IndexedToken: Hashable {
            let index: Int
            let token: TokenSyntax
            init(index: Int) {
                self.index = index
                self.token = "_\(raw: index)"
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