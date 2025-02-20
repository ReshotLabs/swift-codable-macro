//
//  DataTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/19.
//

import Foundation


/// Transformation that encode Data as Base64 string
public struct DataBase64Transform: EvenCodingTransformProtocol {
    
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



extension EvenCodingTransformProtocol where Self == DataBase64Transform {
    /// Transformation that encode Data as Base64 string
    public static func dataBase64Transform(options: Data.Base64EncodingOptions = []) -> Self {
        .init(options: options)
    }
}
