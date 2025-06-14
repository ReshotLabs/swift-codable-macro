//
//  CodingTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/17.
//

import Foundation


/// Protocol of rules for transformance before encoding / after decoding
public protocol EvenCodingTransformProtocol {
    
    /// The type of data actually be encoded
    associatedtype TransformedType
    /// The type of the property to be encoded / decoded
    associatedtype PropertyType
    
    /// Convert instance of the property to type for actual encoding
    func encodeTransform(_ value: PropertyType) throws -> TransformedType
    /// Convert instance for encoding back to the type of the property
    func decodeTransform(_ value: TransformedType) throws -> PropertyType
    
}



public struct AnyCodingTransform<PropertyType, TransformedType>: EvenCodingTransformProtocol, Sendable {
    
    public let encode: @Sendable (PropertyType) throws -> TransformedType
    public let decode: @Sendable (TransformedType) throws -> PropertyType
    
    public init(
        encode: @escaping @Sendable (PropertyType) throws -> TransformedType,
        decode: @escaping @Sendable (TransformedType) throws -> PropertyType
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



/// A function that does nothing and return the parameter immediately,
/// just used to help with type inference
@inlinable @inline(__always)
public func codingTransformPassThroughWithTypeInference<Transformer: EvenCodingTransformProtocol>(
    _ transform: Transformer
) -> Transformer {
    transform
}



/// Error thrown during transformation process
public struct CodingTransformError<T: EvenCodingTransformProtocol>: LocalizedError, Sendable {
    /// Error message
    public let message: String
    public var errorDescription: String? { message }
    /// The type responsible for the transformation process
    public var transformerType: T.Type {
        T.self
    }
    public init(transformerType: T.Type, message: String) {
        self.message = message
    }
}
