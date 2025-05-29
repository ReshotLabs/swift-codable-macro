//
//  Helpers.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/1.
//


/// Return the type of the input expression,
/// where the expression will not be evaluated (due to the use of autoclosure)
///
/// ```swift
/// func test() -> Int {
///     print("executed")
///     return 1
/// }
///
/// print(codableMacroStaticType(of: test()))
/// // > Int
/// // the `executed` will not be printed
/// ```
public func codableMacroStaticType<T>(of _: @autoclosure () throws -> T) -> T.Type {
    return T.self
}



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



/// Default value configuration for ``SingleValueCodableProtocol``
/// 
/// Work exactly the same as the `Optional` type in Swift, used just to avoid nested Optional 
public enum CodingDefaultValue<T> {
    /// No default value 
    case none 
    /// Has default value
    case value(T)
}


extension CodingDefaultValue: Sendable where T: Sendable {}
extension CodingDefaultValue: Equatable where T: Equatable {}



/// Behaviour for elements that cannot be decoded correctly in an encoded sequence (e.g.: JSON Array)
public enum SequenceCodingFieldErrorStrategy<T> {
    /// Throw [`DecodingError`]
    ///
    /// [`DecodingError`]: https://developer.apple.com/documentation/swift/decodingerror
    case throwError
    /// Skip this element and continue
    case ignore
    /// Apply and default value and continue
    case value(T)
}



extension SequenceCodingFieldErrorStrategy: Sendable where T: Sendable {}
extension SequenceCodingFieldErrorStrategy: Equatable where T: Equatable {}



public protocol EnumCodableProtocol: Codable {
    typealias DefaultValue = CodingDefaultValue<Self>
    static var codingDefaultValue: DefaultValue { get }
}


extension EnumCodableProtocol {
    public static var codingDefaultValue: DefaultValue { .none }
}



/// caseKey: used to identify the enum case. the name of the case or customed key 
/// payload: the value of the enum case, can be associated value or raw value 
public enum EnumCodableOption: Sendable {
    /// { 
    ///     caseKey: payload
    /// }
    case externalKeyed
    /// {
    ///     "type": caseKey,
    ///     "payload": payload
    /// }
    case adjucentKeyed(typeKey: StaticString = "type", payloadKey: StaticString = "payload")
    /// {
    ///     "type": caseKey,
    ///     payload         // MUST NOT be array or single value
    /// }
    case internalKeyed(typeKey: StaticString = "type")
    /// payload             // MUST NOT specify type, payload only 
    case unkeyed
    /// payload             // MUST NOT specify any customization and MUST be RawRepresentable
    case rawValueCoded
}



public struct EnumCaseCodingKey: Sendable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(stringLiteral value: StaticString) {}
    public init(integerLiteral value: Int) {}
    public init(floatLiteral value: Double) {}
    public static var auto: Self { 0 }
}



public enum EnumCaseCodingEmptyPayloadOption: Sendable, Equatable {
    case null
    case emptyObject
    case emptyArray
    case nothing
}



public enum EnumCaseCodingPayload: Sendable, Equatable {
    case singleValue 
    case array
    case object
    public static func object(keys: StaticString...) -> Self {
        return .object
    }
}



/// A type that can always be decoded sucessfully as long as the data itself is not corrupted
public struct DummyDecodableType: Sendable, Codable {
    public init() {}
}


extension UnkeyedDecodingContainer {
    /// Skip one element
    public mutating func skip() throws {
        if !isAtEnd {
            _ = try decode(DummyDecodableType.self)
        }
    }
}
