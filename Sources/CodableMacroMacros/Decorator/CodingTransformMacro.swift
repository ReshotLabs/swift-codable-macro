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
    
    
    static func processProperty(
        _ propertyInfo: PropertyInfo,
        macroNodes: [AttributeSyntax]
    ) throws(DiagnosticsError) -> Spec? {
        
        guard propertyInfo.type != .computed || macroNodes.isEmpty else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.attachTypeError)
        }
        
        guard macroNodes.count <= 1 else {
            throw .diagnostic(node: propertyInfo.name, message: .decorator.general.duplicateMacro(name: "CodingTransformMacro"))
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
