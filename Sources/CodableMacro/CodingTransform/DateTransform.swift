//
//  DateTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/18.
//

import Foundation


/// Transformation that encode Date as ISO8601 string
public struct ISO8601DateFormatTransform: EvenCodingTransformProtocol {
        
    public func encodeTransform(_ value: Date) throws -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: value)
    }
    
    public func decodeTransform(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else {
            throw CodingTransformError(
                transformerType: Self.self,
                message: "\(value) is not a valid ISO8601 date"
            )
        }
        return date
    }
    
}



extension EvenCodingTransformProtocol where Self == ISO8601DateFormatTransform {
    /// Transformation that encode Date as ISO8601 string
    public static var iso8601DateTransform: ISO8601DateFormatTransform { .init() }
}



/// Transformation that encode Date to string in the specified format
public struct DateFormatTransform: EvenCodingTransformProtocol {
    
    /// The format of the data string
    public let format: String
    private let formatter: DateFormatter
    
    public init(format: String) {
        self.format = format
        self.formatter = .init()
        formatter.dateFormat = format
    }
    
    public func encodeTransform(_ value: Date) throws -> String {
        formatter.string(from: value)
    }
    
    public func decodeTransform(_ value: String) throws -> Date {
        guard let date = formatter.date(from: value) else {
            throw CodingTransformError(
                transformerType: Self.self,
                message: "\(value) is not a valid date string of format `\(format)`"
            )
        }
        return date
    }
    
}



extension EvenCodingTransformProtocol where Self == DateFormatTransform {
    /// Transformation that encode Date to string in the specified format
    public static func dateFormatTransform(format: String) -> Self {
        .init(format: format)
    }
}



/// Transformation that encode Date as Double
public struct DoubleDateFormatTransform: EvenCodingTransformProtocol {
    
    /// The relative reference date for calculating the Double
    public let referenceDate: Date
    
    public init(referenceDate: Date = .init(timeIntervalSince1970: 0)) {
        self.referenceDate = referenceDate
    }
    
    public func encodeTransform(_ value: Date) throws -> Double {
        value.timeIntervalSince(referenceDate)
    }
    
    public func decodeTransform(_ value: Double) throws -> Date {
        .init(timeInterval: value, since: referenceDate)
    }
    
}



extension EvenCodingTransformProtocol where Self == DoubleDateFormatTransform {
    /// Transformation that encode Date as Double
    public static func doubleDateTransform(
        referenceDate: Date = .init(timeIntervalSince1970: 0)
    ) -> DoubleDateFormatTransform { .init(referenceDate: referenceDate) }
}

