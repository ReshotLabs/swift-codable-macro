import SwiftSyntax
import SwiftSyntaxMacros


extension MacroExpansionContext {

    func isInSource(_ syntax: some SyntaxProtocol) -> Bool {
        self.location(of: syntax) != nil
    }

}