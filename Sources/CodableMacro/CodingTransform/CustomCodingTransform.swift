//
//  CustomCodingTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/19.
//

import Foundation



/// Fully custom transformation by specifying the transformation closures
public typealias CustomCodingTransform<PropertyType, TransformedType> = AnyCodingTransform<PropertyType, TransformedType>



extension EvenCodingTransformProtocol where Self == CustomCodingTransform<Any, Any> {
    
    /// Create a fully custom Coding Transformation with the provided closures
    static func customTransform<PropertyType, TransformedType>(
        for propertyType: PropertyType.Type = PropertyType.self,
        encode: @escaping @Sendable (PropertyType) throws -> TransformedType,
        decode: @escaping @Sendable (TransformedType) throws -> PropertyType
    ) -> CustomCodingTransform<PropertyType, TransformedType> {
        .init(encode: encode, decode: decode)
    }
    
}
