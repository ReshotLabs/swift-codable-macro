import SwiftSyntax


extension SyntaxProtocol {

    static func ~= (lhs: Self, rhs: String) -> Bool {
        return lhs.trimmedDescription == rhs
    }

}



extension TokenSyntax {

    static func ~= (lhs: Self, rhs: String) -> Bool {
        return lhs.trimmed.text == rhs
    }

}