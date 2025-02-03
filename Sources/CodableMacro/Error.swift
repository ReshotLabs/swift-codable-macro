//
//  Error.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/2.
//

import Foundation


public struct CodingValidationError: LocalizedError, CustomStringConvertible {
    
    public let type: String
    public let property: String
    public let validationExpr: String
    public let value: String
    
    public init(type: String, property: String, validationExpr: String, value: String) {
        self.type = type
        self.property = property
        self.validationExpr = validationExpr
        self.value = value
    }
    
    public var errorDescription: String? { description }
    
    public var description: String {
        "ValidationError when decoding \(type).\(property): Value `\(value)` Fail to match requirement `\(validationExpr)`"
    }
    
}
