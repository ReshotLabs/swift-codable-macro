//
//  CodingPrimitive.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/18.
//


/// Basic primitives in the encoded data format
///
/// It also conforms to Codable, so feel free to use it in ``CodingTransformProtocol``
public enum CodingPrimitive<Number: Numeric & Codable> {
    case string(String)
    case number(Number)
    case bool(Bool)
    case null
}



extension CodingPrimitive: Codable {
        
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .string(let value):
                try container.encode(value)
            case .number(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            case .null:
                try container.encodeNil()
        }
    }
    
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = if let stringValue = try? container.decode(String.self) {
            .string(stringValue)
        } else if let intValue = try? container.decode(Number.self) {
            .number(intValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            .bool(boolValue)
        } else if container.decodeNil() {
            .null
        } else {
            throw DecodingError.typeMismatch(
                CodingPrimitive.self,
                .init(codingPath: container.codingPath, debugDescription: "cannot decode primitive")
            )
        }
    }
    
}
