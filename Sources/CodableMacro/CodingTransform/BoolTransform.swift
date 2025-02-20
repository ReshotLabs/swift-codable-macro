//
//  BoolTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/19.
//

import Foundation


/// Transformation that encode Boolean as bool, string or int
///
/// It alwasy support decoding bool from bool, string and int, but for encoding, it needs to
/// be specified using `transformOption`
public struct BoolTransform: EvenCodingTransformProtocol {
    
    /// Specify the actual type for storing the boolean
    ///
    /// The type can be:
    /// * `bool`: store directly as bool primitive
    /// * `int`: store as integer primitive (1 for true and 0 for false)
    /// * `string`: store as string primitive ("true" for true and "false" for false
    /// * `customString(true:false:)`: store as custom string primitive
    ///
    /// - Note: This option only affect encoding, decoding will always support both
    /// int primitive and string primitive
    public let transformOption: TransformOption
    
    
    public init(transformOption: TransformOption = .bool) {
        self.transformOption = transformOption
    }
    
    
    public func encodeTransform(_ value: Bool) throws -> TransformedValue {
        return switch transformOption {
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
                let (trueStr, falseStr) = switch transformOption {
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
    
    
    public enum TransformedValue {
        case string(String)
        case bool(Bool)
        case int(Int)
    }
    
    
    public enum TransformOption {
        case bool, number, string, customString(true: String, false: String)
    }
    
}



extension BoolTransform.TransformedValue: Codable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case let .bool(value): try container.encode(value)
            case let .string(value): try container.encode(value)
            case let .int(value): try container.encode(value)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
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



extension EvenCodingTransformProtocol where Self == BoolTransform {
    /// Transformation that encode Boolean as bool, string or int
    ///
    /// It alwasy support decoding bool from bool, string and int, but for encoding, it needs to
    /// be specified using `option`
    public static func boolTransform(option: Self.TransformOption = .bool) -> Self {
        .init(transformOption: option)
    }
}
