import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct EnumCaseInfo: Sendable, Equatable, Hashable {

    let name: TokenSyntax
    let rawValue: LiteralValue?
    let associatedValues: [AssociatedValue]
    let attributes: [AttributeSyntax]


    struct AssociatedValue: Sendable, Equatable, Hashable {
        let label: TokenSyntax?
        let type: TypeSyntax
        let defaultValue: ExprSyntax?
        let rawSyntax: EnumCaseParameterSyntax
    }


    enum Error {
        static func missingTypeExpr() -> SyntaxInfoDiagnosticMessage {
            .init(id: "missing_type_expr", message: "Missing type expression")
        }
    }

}


extension EnumCaseInfo {

    static func extract(from syntax: EnumCaseDeclSyntax) throws(DiagnosticsError) -> [Self] {
        return try syntax.elements.map { caseElement throws(DiagnosticsError) in 
            .init(
                name: caseElement.name, 
                rawValue: try (caseElement.rawValue?.value).map { value throws(DiagnosticsError) in try .init(from: value) }, 
                associatedValues: try (caseElement.parameterClause?.parameters.map(AssociatedValue.extract(from:))) ?? [], 
                attributes: syntax.attributes.compactMap { $0.as(AttributeSyntax.self) }
            )
        }
    }

}



extension EnumCaseInfo.AssociatedValue {

    static func extract(from syntax: EnumCaseParameterSyntax) throws(DiagnosticsError) -> Self {
        let label = switch syntax.firstName?.trimmed.text {
            case .none: nil
            case .some("_"): nil
            case .some(_): syntax.firstName
        } as TokenSyntax?
        return .init(
            label: label,
            type: syntax.type,
            defaultValue: syntax.defaultValue?.value,
            rawSyntax: syntax
        )
    }

}



extension SyntaxInfoDiagnosticMessageGroup {
    static var enumCaseInfo: EnumCaseInfo.Error.Type {
        EnumCaseInfo.Error.self
    }
}


enum Test {
    case a(Int = 1)
}

