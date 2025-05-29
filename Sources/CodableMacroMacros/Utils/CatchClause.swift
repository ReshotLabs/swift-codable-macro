import SwiftSyntax
import SwiftSyntaxBuilder



extension DoStmtSyntax {

    mutating func addCatchClause(
        errors: [ExprSyntax], 
        @CodeBlockItemListBuilder bodyBuilder: () throws -> CodeBlockItemListSyntax
    ) throws {

        let catchItems = errors.enumerated().map { i, error in 
            let traiilingTrivia = (i == errors.count - 1 ? nil : ", ") as Trivia?
            return CatchItemSyntax(pattern: ExpressionPatternSyntax(expression: error, trailingTrivia: traiilingTrivia)) 
        }

        self.catchClauses.append(
            try CatchClauseSyntax(
                catchItems: .init(catchItems), 
                bodyBuilder: bodyBuilder
            ) 
        )

    }


    func addingCatchClause(
        errors: [ExprSyntax], 
        @CodeBlockItemListBuilder bodyBuilder: () throws -> CodeBlockItemListSyntax
    ) throws -> DoStmtSyntax {
        var copy = self
        try copy.addCatchClause(errors: errors, bodyBuilder: bodyBuilder)
        return copy
    }

}