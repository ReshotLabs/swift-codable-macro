//
//  DataTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/19.
//

import Foundation


/// Coding Transformation that transform Data to Base64 string
public struct DataBase64Transform: EvenCodingTransformProtocol, Sendable {
    
    /// Options when encoding the Data to Base64
    public let options: Data.Base64EncodingOptions
    
    public init(options: Data.Base64EncodingOptions = []) {
        self.options = options
    }
    
    public func encodeTransform(_ value: Data) throws -> String {
        value.base64EncodedString(options: options)
    }
    
    public func decodeTransform(_ value: String) throws -> Data {
        guard let data = Data(base64Encoded: value) else {
            throw CodingTransformError(
                transformerType: Self.self,
                message: "\(value) is not a valid base64 encoded string"
            )
        }
        return data
    }
    
}



extension AnyCodingTransform where Self.PropertyType == Data {
    
    public enum DataCodingTransform {
        
        /// Create a Coding Transformation that transform Data to Base64 string
        public static func base64Transform(options: Data.Base64EncodingOptions = []) -> DataBase64Transform {
            .init(options: options)
        }
        
    }
    
}



extension EvenCodingTransformProtocol where Self == AnyCodingTransform<Data, Any> {
    
    /// Access a group of Coding Transformation for `Data` type 
    public static var data: AnyCodingTransform<Data, Any>.DataCodingTransform.Type {
        AnyCodingTransform<Data, Any>.DataCodingTransform.self
    }
    
}
