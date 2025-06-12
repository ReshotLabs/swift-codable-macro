//
//  SingleValueCodableProtocol.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Protocol of types that delegate the decoding / encoding process to instances of another type
///
/// It has provided the implementation of [`encode(to:)`] and [`init(from:)`].
/// Require to implement:
/// * ``singleValueEncode()`` to convert the instance to an instance of another type
/// for being encoded
/// * ``init(from:)`` to create an instance of this type using an instance of another type
/// being decoded
///
/// [`encode(to:)`]: https://developer.apple.com/documentation/swift/encodable/encode(to:)-7ibwv
/// [`init(from:)`]: https://developer.apple.com/documentation/swift/decodable/init(from:)-8ezpn
public protocol SingleValueCodableProtocol: Codable {
    
    /// The type for actual encoding / decoding process
    associatedtype CodingValue: Codable
    typealias DefaultValue = CodingDefaultValue<CodingValue>
    
    /// The default value to use when decoding
    static var singleValueCodingDefaultValue: CodingDefaultValue<CodingValue> { get }
    
    /// Convert the instance to an instance of another type for being encoded
    func singleValueEncode() throws -> CodingValue
    
    /// Create an instance of this type using an instance of another type being decoded
    init(from codingValue: CodingValue) throws
    
}



extension SingleValueCodableProtocol {
    
    public init(from decoder: any Decoder) throws {
        switch Self.singleValueCodingDefaultValue {
            case .value(let defaultValue):
                let decodedValue = (try? CodingValue(from: decoder)) ?? defaultValue
                try self.init(from: decodedValue)
            case .none:
                try self.init(from: .init(from: decoder))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        try self.singleValueEncode().encode(to: encoder)
    }
    
    public static var singleValueCodingDefaultValue: DefaultValue { .none }
    
}



/// Protocol of types that delegate the decoding / encoding process to instances of another type
/// while the type itself inherits `Codable` conformance from another class
///
/// It's very similar to ``SingleValueCodableProtocol`` but provides an additional argument `decoder`
/// in the `init(from:)` method, which is useful for calling the `super.init(from:)` method
///
/// It has provided the implementation of [`encode(to:)`] and [`init(from:)`].
/// Require to implement:
/// * ``singleValueEncode()`` to convert the instance to an instance of another type
/// for being encoded
/// * ``init(from:)`` to create an instance of this type using an instance of another type
/// being decoded
///
/// - Seealso: ``SingleValueCodableProtocol``
///
/// [`encode(to:)`]: https://developer.apple.com/documentation/swift/encodable/encode(to:)-7ibwv
/// [`init(from:)`]: https://developer.apple.com/documentation/swift/decodable/init(from:)-8ezpn
public protocol InheritedSingleValueCodableProtocol: AnyObject {
    
    /// The type for actual encoding / decoding process
    associatedtype CodingValue: Codable
    typealias DefaultValue = CodingDefaultValue<CodingValue>
    
    /// The default value to use when decoding
    static var singleValueCodingDefaultValue: CodingDefaultValue<CodingValue> { get }
    
    /// Convert the instance to an instance of another type for being encoded
    func singleValueEncode() throws -> CodingValue
    
    /// Create an instance of this type using an instance of another type being decoded
    init(from codingValue: CodingValue, decoder: Decoder) throws
    
}



extension InheritedSingleValueCodableProtocol {
    public static var singleValueCodingDefaultValue: CodingDefaultValue<CodingValue> { .none }
}
