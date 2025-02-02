//
//  EncodeTransformMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/1.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct EncodeTransformMacro: PeerMacro {
    
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
    
}
