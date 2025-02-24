//
//  NumberTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/18.
//

import Foundation



/// Transformation that encode Numeric number as string or number
///
/// It always support decoding the value from number or string, but for encoding, it needs
/// to be specified using `transformOption`
public struct NumberTypeTransform<Number>: EvenCodingTransformProtocol
where Number: Numeric & LosslessStringConvertible {
    
    /// Specify the actual type for storing the number
    ///
    /// The type can be:
    /// * `number`: store directly as number primitive
    /// * `string`: store as string
    ///
    /// - Note: This option only affect encoding, decoding will always support both
    /// int primitive and string primitive
    public let transformOption: TransformOption
    
    public init(transformOption: TransformOption = .number) {
        self.transformOption = transformOption
    }
    
    
    public func encodeTransform(_ value: Number) throws -> TransformedValue {
        switch transformOption {
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
    
    
    
    public enum TransformedValue {
        case number(Number)
        case string(String)
    }
    
    
    public enum TransformOption {
        // always try to encode as number
        case number
        // always try to encode as string
        case string
    }
    
}


extension NumberTypeTransform.TransformedValue: Codable where Number: Codable {
    
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



extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Int> {
    /// Transformation that encode `Int` as string or number
    public static func intTypeTransform(option: Self.TransformOption = .number) -> Self {
        return .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<UInt> {
    /// Transformation that encode `UInt` as string or number
    public static func uIntTypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Int8> {
    /// Transformation that encode `Int8` as string or number
    public static func int8TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<UInt8> {
    /// Transformation that encode `UInt8` as string or number
    public static func uInt8TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Int16> {
    /// Transformation that encode `Int16` as string or number
    public static func int16TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<UInt16> {
    /// Transformation that encode `UInt16` as string or number
    public static func uInt16TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Int32> {
    /// Transformation that encode `Int32` as string or number
    public static func int32TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<UInt32> {
    /// Transformation that encode `UInt32` as string or number
    public static func uInt32TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Int64> {
    /// Transformation that encode `Int64` as string or number
    public static func int64TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<UInt64> {
    /// Transformation that encode `UInt64` as string or number
    public static func uInt64TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

@available(macOS 15, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2, *)
extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Int128> {
    /// Transformation that encode `Int128` as string or number
    public static func int128TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

@available(macOS 15, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2, *)
extension EvenCodingTransformProtocol where Self == NumberTypeTransform<UInt128> {
    /// Transformation that encode `UInt128` as string or number
    public static func uInt128TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Float> {
    /// Transformation that encode `Float` as string or number
    public static func floatTypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Double> {
    /// Transformation that encode `Float` as string or number
    public static func doubleTypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}

@available(macOS 11, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension EvenCodingTransformProtocol where Self == NumberTypeTransform<Float16> {
    /// Transformation that encode `Float16` as string or number
    public static func float16TypeTransform(option: Self.TransformOption = .number) -> Self {
        .init(transformOption: option)
    }
}
