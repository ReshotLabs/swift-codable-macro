//
//  IndentRemover.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/21.
//

import SwiftSyntax


final class IndentRemover: SyntaxRewriter {
    
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        
        var leadingTrivia = Array(token.leadingTrivia)
        if leadingTrivia.count >= 2, leadingTrivia[0].isNewline || leadingTrivia[1].isSpaceOrTab {
            leadingTrivia = leadingTrivia.compactMap {
                switch $0 {
                    case .spaces(let n) where n > 1: nil
                    case .tabs(let n) where n > 1: .tabs(1)
                    case .lineComment, .blockComment, .docLineComment, .docBlockComment: nil
                    default: $0
                } as TriviaPiece?
            }
        }
        
        let trailingTrivia = token.trailingTrivia.compactMap {
            switch $0 {
                case .spaces(let n) where n > 1: .spaces(1)
                case .tabs(let n) where n > 1: .tabs(1)
                case .lineComment, .blockComment, .docLineComment, .docBlockComment: nil
                default: $0
            } as TriviaPiece?
        }
        
        var result = token.detached
        result.leadingTrivia = .init(pieces: leadingTrivia)
        result.trailingTrivia = .init(pieces: trailingTrivia)
        
        return result
        
    }
    
}
