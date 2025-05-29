import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct SequenceCodingFieldMacro: CodingDecoratorMacro {

    struct Spec {
        var path: [String]
        var elementEncodedType: ExprSyntax
        var defaultValueOnMissing: ErrorStrategy = .throwError
        var defaultValueOnMismatch: ErrorStrategy = .throwError
        var decodeTransformExpr: ExprSyntax? = nil 
        var encodeTransformExpr: ExprSyntax? = nil
    }


    enum ErrorStrategy: Equatable, Hashable {

        case throwError, ignore, value(ExprSyntax)

        init(expr: ExprSyntax?) throws(DiagnosticsError) {

            guard let expr else { 
                self = .throwError
                return 
            }

            if let expr = expr.as(FunctionCallExprSyntax.self) {

                guard 
                    let memberAccessExpr = expr.calledExpression.as(MemberAccessExprSyntax.self),
                    memberAccessExpr.declName.baseName.trimmed.text == "value"
                else {
                    throw .diagnostic(node: expr, message: .decorator.codingSequence.errorStrategyNotRawEnumCase)
                }

                guard 
                    expr.arguments.count == 1,
                    let argumentExpr = expr.arguments.first?.expression
                else {
                    throw .diagnostic(node: expr, message: .decorator.codingSequence.errorStrategyNotRawEnumCase)
                }

                self = .value(argumentExpr)

            } else {

                guard let expr = expr.as(MemberAccessExprSyntax.self) else {
                    throw .diagnostic(node: expr, message: .decorator.codingSequence.errorStrategyNotRawEnumCase)
                }
                switch expr.declName.baseName.trimmed.text {
                    case "throwError": self = .throwError
                    case "ignore": self = .ignore
                    default: throw .diagnostic(node: expr, message: .decorator.codingSequence.errorStrategyNotRawEnumCase)
                }

            }

        }

    }


    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeledVarArg("subPath", canIgnore: true),
        .labeled("elementEncodedType"),
        .labeled("default", canIgnore: true), 
        .labeledVarArg("onMissing", canIgnore: true), 
        .labeledVarArg("onMismatch", canIgnore: true),
        .labeled("decodeTransform", canIgnore: true),
        .labeled("encodeTransform", canIgnore: true),
    ]

    static func processProperty(
        _ propertyInfo: PropertyInfo, 
        macroNodes: [AttributeSyntax],
        context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> Spec? {

        guard !macroNodes.isEmpty else { return nil }
        
        guard propertyInfo.type != .computed else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.attachTypeError)
        }

        guard macroNodes.count == 1 else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.duplicateMacro(name: "SequenceCodingField"))
        }

        guard let macroNode = macroNodes.first else { return nil } 

        guard let arguments = try macroNode.arguments?.grouped(with: macroArgumentsParsingRule) else {
            throw .diagnostic(node: macroNode, message: .decorator.general.noArguments())
        }

        let pathElements = if arguments[0].isEmpty {
            [] as [String]
        } else {
            arguments[0].compactMap {
                $0.expression.as(StringLiteralExprSyntax.self)?.segments.description
            }
        }
        guard let encodedType = arguments[1].first?.expression else {
            throw .diagnostic(node: macroNode, message: .decorator.general.missingArgument("elementEncodedType"))
        }
        let defaultValue = arguments[2].first?.expression
        let onMissing = arguments[3].first?.expression ?? defaultValue
        let onMismatch = arguments[4].first?.expression ?? defaultValue
        let decodeTransformExpr = arguments[5].first?.expression.trimmed
        let encodeTransformExpr = arguments[6].first?.expression.trimmed

        return .init(
            path: pathElements, 
            elementEncodedType: encodedType,
            defaultValueOnMissing: try .init(expr: onMissing), 
            defaultValueOnMismatch: try .init(expr: onMismatch), 
            decodeTransformExpr: decodeTransformExpr,
            encodeTransformExpr: encodeTransformExpr
        )

    }

    
    enum Error {
        static let errorStrategyNotRawEnumCase: CodingDecoratorMacroDiagnosticMessage = .init(
            id: "error_strategy_not_raw_value", 
            message: "The error strategy must be a raw enum case (e.g.: .throwError, .ignore, .value(_:))", 
            severity: .error
        )
    }

}


extension CodingDecoratorMacroDiagnosticMessageGroup {
    static var codingSequence: SequenceCodingFieldMacro.Error.Type {
        SequenceCodingFieldMacro.Error.self
    }
}