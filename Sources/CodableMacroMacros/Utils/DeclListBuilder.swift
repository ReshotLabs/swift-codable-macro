import SwiftSyntax


@resultBuilder
struct DeclListBuilder {

    static func buildBlock(_ components: [DeclSyntaxProtocol]...) -> [DeclSyntaxProtocol] {
        return components.flatMap(\.self)
    }

    static func buildArray(_ components: [[any DeclSyntaxProtocol]]) -> [any DeclSyntaxProtocol] {
        return components.flatMap(\.self)
    }

    static func buildEither(first component: [any DeclSyntaxProtocol]) -> [any DeclSyntaxProtocol] {
        return component
    }

    static func buildEither(second component: [any DeclSyntaxProtocol]) -> [any DeclSyntaxProtocol] {
        return component
    }

    static func buildOptional(_ component: [any DeclSyntaxProtocol]?) -> [any DeclSyntaxProtocol] {
        return component ?? []
    }

    static func buildExpression(_ expression: DeclSyntax?) -> [any DeclSyntaxProtocol] {
        return if let expression { [expression] } else { [] }
    }

    static func buildExpression(_ expression: (any DeclSyntaxProtocol)?) -> [any DeclSyntaxProtocol] {
        return if let expression { [expression] } else { [] }
    }

    static func buildExpression(_ expression: [any DeclSyntaxProtocol]?) -> [any DeclSyntaxProtocol] {
        return expression ?? []
    }

    static func buildExpression(_ expression: (any ExprSyntaxProtocol)?) -> [any DeclSyntaxProtocol] {
        return if let expression { ["\(expression)" as DeclSyntax] } else { [] }
    }

    static func buildExpression(_ expression: [any ExprSyntaxProtocol]?) -> [any DeclSyntaxProtocol] {
        return expression?.map { "\($0)" as DeclSyntax } ?? []
    }

}



func buildDeclSyntaxList(@DeclListBuilder _ builder: () throws -> [any DeclSyntaxProtocol]) rethrows -> [DeclSyntax] {
    return try builder().map(DeclSyntax.init(fromProtocol:))
}