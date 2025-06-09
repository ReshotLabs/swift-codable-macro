//
//  CodingTransformMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/17.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


struct CodingTransformMacro: CodingDecoratorMacro {
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [.varArg()]
    
    
    static func extractSetting(
        from macroNodes: [AttributeSyntax],
        in context: some MacroExpansionContext
    ) throws(DiagnosticsError) -> Spec? {
        
        guard macroNodes.count < 2 else {
            throw .diagnostics(macroNodes.map { .init(node: $0, message: .decorator.general.duplicateMacro(name: "CodingTransform")) })
        }
        
        guard let macroNode = macroNodes.first else { return nil }
        
        guard let arguments = try macroNode.arguments?.grouped(with: macroArgumentsParsingRule) else {
            throw .diagnostic(node: macroNode, message: .decorator.general.noArguments())
        }
        
        let transformerTypeList = arguments[0].map(\.expression.trimmed)
        
        guard let decodeSourceType = transformerTypeList.last?.trimmed else {
            throw .diagnostic(node: macroNode, message: .decorator.general.missingArgument("transformers"))
        }
        
        return .init(
            decodeSourceType: "codableMacroStaticType(of: codingTransformPassThroughWithTypeInference(\(decodeSourceType))).TransformedType.self",
            decodeTransforms: transformerTypeList.reversed().map { "codingTransformPassThroughWithTypeInference(\($0)).decodeTransform" },
            encodeTransforms: transformerTypeList.map { "codingTransformPassThroughWithTypeInference(\($0)).encodeTransform" }
        )
        
    }
    
    
    struct Spec {
        let decodeSourceType: ExprSyntax
        let decodeTransforms: [ExprSyntax]
        let encodeTransforms: [ExprSyntax]
    }
    
}
