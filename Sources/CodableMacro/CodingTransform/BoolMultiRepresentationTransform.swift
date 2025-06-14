//
//  BoolMultiRepresentationTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/19.
//

import Foundation


/// Transformation that transform Boolean as bool, string or int
///
/// It alwasy support decoding bool from bool, string and int, but for encoding, it needs to
/// be specified using ``BoolMultiRepresentationTransform/encodeTargetRepresentation``
public struct BoolMultiRepresentationTransform: EvenCodingTransformProtocol, Sendable {
    
    /// Specify the actual type for storing the boolean
    ///
    /// The type can be:
    /// * ``Representation/bool``: transform to a bool value
    /// * ``Representation/number``: transform to a integer value (1 for true and 0 for false)
    /// * ``Representation/string``: trasnform to a string value ("true" for true and "false" for false)
    /// * ``Representation/customString(true:false:)``: transform to a custom string value
    ///
    /// - Note: This option only affect encoding, decoding will always support both
    /// int primitive and string primitive
    public let encodeTargetRepresentation: Representation
    
    
    public init(encodeTargetRepresentation: Representation = .bool) {
        self.encodeTargetRepresentation = encodeTargetRepresentation
    }
    
    
    public func encodeTransform(_ value: Bool) throws -> TransformedValue {
        return switch encodeTargetRepresentation {
            case .bool: .bool(value)
            case .number: .int(value ? 1 : 0)
            case .string: .string(value ? "true" : "false")
            case .customString(let trueStr, let falseStr): .string(value ? trueStr : falseStr)
        }
    }
    
    
    public func decodeTransform(_ value: TransformedValue) throws -> PropertyType {
        switch value {
            case .bool(let value): return value
            case .int(let value):
                return switch value {
                    case 0: false
                    case 1: true
                    default: throw CodingTransformError(
                        transformerType: Self.self,
                        message: "\(value) cannot be decoded as Bool"
                    )
                }
            case .string(let value):
                let (trueStr, falseStr) = switch encodeTargetRepresentation {
                    case let .customString(trueStr, falseStr): (trueStr, falseStr)
                    default: ("true", "false")
                }
                return switch value {
                    case trueStr: true
                    case falseStr: false
                    default: throw CodingTransformError(
                        transformerType: Self.self,
                        message: "\(value) cannot be decoded as Bool"
                    )
                }
        }
    }
    
    
    /// The type for the encode transform output
    public enum TransformedValue: Sendable {
        case string(String)
        case bool(Bool)
        case int(Int)
    }
    
    
    /// Representations that can be transformed from a `Bool` value
    public enum Representation: Sendable {
        /// transform to a bool value
        case bool
        /// transform to a integer value (1 for true and 0 for false)
        case number
        /// trasnform to a string value ("true" for true and "false" for false)
        case string
        /// transform to a custom string value
        case customString(true: String, false: String)
    }
    
}



extension BoolMultiRepresentationTransform.TransformedValue: Codable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case let .bool(value): try container.encode(value)
            case let .string(value): try container.encode(value)
            case let .int(value): try container.encode(value)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        if let boolValue = try? Bool(from: decoder) {
            self = .bool(boolValue)
        } else if let intValue = try? Int(from: decoder) {
            self = .int(intValue)
        } else if let stringValue = try? String(from: decoder) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "value cannot be decoded as Bool"
                )
            )
        }
    }
    
}



extension AnyCodingTransform where Self.PropertyType == Bool {
    
    public enum BoolCodingTransform {
        /// Create a Coding Transformation that transform Boolean to bool, string or int
        ///
        /// It alwasy support decoding bool from bool, string and int, but for encoding, it needs to
        /// be specified using `option`
        public static func multiRepresentationTransform(
            encodeTo targetRepresentation: BoolMultiRepresentationTransform.Representation = .bool
        ) -> BoolMultiRepresentationTransform {
            .init(encodeTargetRepresentation: targetRepresentation)
        }
    }
    
}



extension EvenCodingTransformProtocol where Self == AnyCodingTransform<Bool, Any> {
    /// Access a group of Coding Transformation for `Bool` type
    public static var bool: AnyCodingTransform<Bool, Any>.BoolCodingTransform.Type {
        return AnyCodingTransform<Bool, Any>.BoolCodingTransform.self
    }
}
