//
//  DateTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/18.
//

import Foundation


/// Coding Transformation that transform Date to ISO8601 formatted string
public struct DateISO8601FormatTransform: EvenCodingTransformProtocol, Sendable {
        
    public func encodeTransform(_ value: Date) throws -> String {
        if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            return value.ISO8601Format()
        } else {
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: value)
        }
    }
    
    public func decodeTransform(_ value: String) throws -> Date {
        if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            return try Date.ISO8601FormatStyle().parse(value)
        } else {
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
    
}



/// Coding Transformation that transform Date to string in the specified format
public struct DateFormatTransform: EvenCodingTransformProtocol, Sendable {
    
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



/// Coding Transformation that transform Date to `TimeInterval` since a specified reference data
public struct DateTimeIntervalTransform: EvenCodingTransformProtocol, Sendable {
    
    /// The relative reference date for calculating the TimeInterval
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



extension AnyCodingTransform where Self.PropertyType == Date {
    
    public enum DateCodingTransform {
        
        /// Create a Coding Transformation that transform Date to ISO8601 formatted string
        public static var iso8601FormatTransform: DateISO8601FormatTransform { .init() }
        
        /// Create a Coding Transformation that transform Date to string in the specified format
        public static func formatTransform(format: String) -> DateFormatTransform {
            .init(format: format)
        }
        
        /// Create a Coding Transformation that transform Date to `TimeInterval` since a
        /// specified reference data
        public static func timeIntervalTransform(
            referenceDate: Date = .init(timeIntervalSince1970: 0)
        ) -> DateTimeIntervalTransform { .init(referenceDate: referenceDate) }
        
    }
    
}



extension EvenCodingTransformProtocol where Self == AnyCodingTransform<Date, Any> {
    
    /// Access a group of Coding Transformation for `Date` type 
    public static var date: AnyCodingTransform<Date, Any>.DateCodingTransform.Type {
        AnyCodingTransform<Date, Any>.DateCodingTransform.self
    }
    
}

