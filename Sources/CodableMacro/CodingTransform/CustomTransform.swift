//
//  CustomTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/19.
//

import Foundation


/// Fully custom transformation by specifying the transformation closures
public struct CustomCodingTransform<PropertyType, TransformedType>: EvenCodingTransformProtocol {
    
    public let encode: (PropertyType) throws -> TransformedType
    public let decode: (TransformedType) throws -> PropertyType
    
    public init(
        encode: @escaping (PropertyType) throws -> TransformedType,
        decode: @escaping (TransformedType) throws -> PropertyType
    ) {
        self.encode = encode
        self.decode = decode
    }
    
    public func encodeTransform(_ value: PropertyType) throws -> TransformedType {
        try encode(value)
    }
    
    public func decodeTransform(_ value: TransformedType) throws -> PropertyType {
        try decode(value)
    }
    
}
