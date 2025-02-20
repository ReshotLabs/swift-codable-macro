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



/// A function that does nothing and return the parameter immediately,
/// just used to help with type inference
@inlinable @inline(__always)
public func codingTransformPassThroughWithTypeInference<Transformer: EvenCodingTransformProtocol>(
    _ transform: Transformer
) -> Transformer {
    transform
}



/// Error thrown during transformation process
public struct CodingTransformError<T: EvenCodingTransformProtocol>: LocalizedError {
    /// The type responsible for the transformation process
    public let transformerType: T.Type
    /// Error message
    public let message: String
    public var errorDescription: String? { message }
    public init(transformerType: T.Type, message: String) {
        self.transformerType = transformerType
        self.message = message
    }
}
