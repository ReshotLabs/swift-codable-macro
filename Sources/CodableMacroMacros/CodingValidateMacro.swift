//
//  CodingValidateMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/2.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


struct CodingValidateMacro: CodingDecoratorMacro {
    
    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("source"),
        .labeled("with"),
    ]
    
    
    static func processProperty(
        _ propertyInfo: PropertyInfo,
        macroNodes: [AttributeSyntax]
    ) throws(DiagnosticsError) -> [ExprSyntax] {
        
        guard propertyInfo.type != .computed else {
            throw .diagnostic(node: propertyInfo.name, message: Error.attachTypeError)
        }
        
        return try macroNodes.map { (attribute) throws(DiagnosticsError) in
            
            guard let arguments = try attribute.arguments?.grouped(with: macroArgumentsParsingRule) else {
                throw .diagnostic(node: attribute, message: Error.noArguments())
            }
            
            guard let validExpr = arguments[1].first?.expression.trimmed else {
                throw .diagnostic(node: attribute, message: Error.missingArgument("validate"))
            }
            
            return validExpr
            
        }
        
    }
    
}



//public struct CodingValidationError: LocalizedError {
//    
//    public let type: String
//    public let property: String
//    public let validationExpr: String
//    
//    public init(type: String, property: String, validationExpr: String) {
//        self.type = type
//        self.property = property
//        self.validationExpr = validationExpr
//    }
//    
//    public var errorDescription: String? {
//        "ValidationError when decoding \(type).\(property): Fail to match requirement \(validationExpr)"
//    }
//    
//}
