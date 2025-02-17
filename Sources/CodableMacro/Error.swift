//
//  Error.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/2.
//

import Foundation


/// Error representing a failure when validating the decoded value
public struct CodingValidationError: LocalizedError, CustomStringConvertible {
    
    /// Name of the type that is being decoded
    public let type: String
    /// Name of the property that cause the error when being decoded
    public let property: String
    /// The validation code
    public let validationExpr: String
    /// The decoded value that fail the validation
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
