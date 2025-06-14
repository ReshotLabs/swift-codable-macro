//
//  NumberTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/18.
//

import Foundation



/// Coding Transformation that transform Numeric number to string or number
///
/// It always support decoding the value from number or string, but for encoding, it needs
/// to be specified using `encodeTargetRepresentation`
public struct NumberMultiRepresentationTransform<Number>: EvenCodingTransformProtocol, Sendable
where Number: Numeric & LosslessStringConvertible {
    
    /// Specify the actual type for storing the number
    ///
    /// The type can be:
    /// * ``Representation/number``: store directly as number primitive
    /// * ``Representation/string``: store as string
    ///
    /// - Note: This option only affect encoding, decoding will always support both
    /// int primitive and string primitive
    public let encodeTargetRepresentation: Representation
    
    public init(encodeTargetRepresentation: Representation = .number) {
        self.encodeTargetRepresentation = encodeTargetRepresentation
    }
    
    
    public func encodeTransform(_ value: Number) throws -> TransformedValue {
        switch encodeTargetRepresentation {
            case .string: return .string(value.description)
            case .number: return .number(value)
        }
    }
    
    
    public func decodeTransform(_ value: TransformedValue) throws -> Number {
        switch value {
            case .number(let numberValue):
                return numberValue
            case .string(let stringValue):
                guard let value = Number(stringValue) else {
                    throw CodingTransformError(
                        transformerType: Self.self,
                        message: "\(value) is not in a valid number"
                    )
                }
                return value
        }
    }
    
    
    
    /// The type for the encode transform output
    public enum TransformedValue {
        case number(Number)
        case string(String)
    }
    
    
    /// Representations that can be transformed from a Number
    public enum Representation: Sendable {
        // always try to encode as number
        case number
        // always try to encode as string
        case string
    }
    
}



extension NumberMultiRepresentationTransform.TransformedValue: Sendable where Number: Sendable {}



extension NumberMultiRepresentationTransform.TransformedValue: Codable where Number: Codable {
    
    public func encode(to encoder: any Encoder) throws {
        switch self {
            case .number(let value):
                try value.encode(to: encoder)
            case .string(let value):
                try value.encode(to: encoder)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        if let value = try? Number(from: decoder) {
            self = .number(value)
        } else if let value = try? String(from: decoder) {
            self = .string(value)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Can not decode to \(Self.self)"
                )
            )
        }
    }
    
}



extension AnyCodingTransform where Self.PropertyType: Numeric {
    
    public enum NumberCodingTransform {
        
        /// Create a Coding Transform that transform Number to string or number
        public static func multiRepresentationTransform(
            encodeTo targetRepresentation: NumberMultiRepresentationTransform<PropertyType>.Representation
        ) -> NumberMultiRepresentationTransform<PropertyType>
        where PropertyType: LosslessStringConvertible {
            return .init(encodeTargetRepresentation: targetRepresentation)
        }
        
    }
    
}



extension EvenCodingTransformProtocol
where Self == AnyCodingTransform<(any Numeric), Any> {
    
    /// Access a group of Coding Transformation for Number
    public static func number<Number: Numeric>(
        _ numberType: Number.Type
    ) -> AnyCodingTransform<Number, Any>.NumberCodingTransform.Type {
        AnyCodingTransform.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Int` type
    public static var int: AnyCodingTransform<Int, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Int, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `UInt` type
    public static var uInt: AnyCodingTransform<UInt, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<UInt, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Int8` type
    public static var int8: AnyCodingTransform<Int8, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Int8, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `UInt8` type
    public static var uInt8: AnyCodingTransform<UInt8, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<UInt8, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Int16` type
    public static var int16: AnyCodingTransform<Int16, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Int16, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `UInt16` type
    public static var uInt16: AnyCodingTransform<UInt16, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<UInt16, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Int32` type
    public static var int32: AnyCodingTransform<Int32, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Int32, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `UInt32` type
    public static var uInt32: AnyCodingTransform<UInt32, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<UInt32, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Int64` type
    public static var int64: AnyCodingTransform<Int64, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Int64, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `UInt64` type
    public static var uInt64: AnyCodingTransform<UInt64, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<UInt64, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Int128` type
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    public static var int128: AnyCodingTransform<Int128, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Int128, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `UInt128` type
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    public static var uInt128: AnyCodingTransform<UInt128, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<UInt128, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Double` type
    public static var double: AnyCodingTransform<Double, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Double, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Float` type
    public static var float: AnyCodingTransform<Float, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Float, Any>.NumberCodingTransform.self
    }
    
    /// Access a group of Coding Transformation for `Float16` type 
    @available(macOS 11, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public static var float16: AnyCodingTransform<Float16, Any>.NumberCodingTransform.Type {
        AnyCodingTransform<Float16, Any>.NumberCodingTransform.self
    }
    
}
