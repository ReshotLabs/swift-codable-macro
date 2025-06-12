//
//  EnumCodableProtocol.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Codable protocol for enum
public protocol EnumCodableProtocol: Codable {
    /// The default value to use when no matching case is found during decoding.
    ///
    /// If it is `nil`, then no default value is set and error will be thrown if no matching
    /// case is found during decoding
    static var codingDefaultValue: Self? { get }
}


extension EnumCodableProtocol {
    public static var codingDefaultValue: Self? { .none }
}



/// Enum Coding Format Options
public enum EnumCodableOption: Sendable {
    /// Encode as an object where the key is the caseKey and the value is the payload.
    ///
    /// * Default caseKey: name of the enum case
    /// * Default payload with no associated value: ``EnumCaseCodingEmptyPayloadOption/emptyObject``
    /// * Default payload with single associated value: ``EnumCaseCodingPayload/singleValue``
    /// * Default payload with multiple associated values: ``EnumCaseCodingPayload/object``
    ///
    /// ```json
    /// {
    ///     <caseKey>: <payload>
    /// }
    /// ```
    ///
    /// > Attention:
    /// > `caseKey` MUST be string
    case externalKeyed
    /// Encode as an object with separated fields for caseKey and payload.
    /// The field names can be configured by the `caseField` and the `payloadField` arguments.
    ///
    /// * Default caseKey: name of the enum case
    /// * Default payload with no associated value: ``EnumCaseCodingEmptyPayloadOption/null``
    /// * Default payload with single associated value: ``EnumCaseCodingPayload/singleValue``
    /// * Default payload with multiple associated values: ``EnumCaseCodingPayload/object``
    ///
    /// ```json
    /// {
    ///     <caseField>: caseKey,
    ///     <payloadField>: payload
    /// }
    /// ```
    case adjucentKeyed(caseField: StaticString = "case", payloadField: StaticString = "payload")
    /// Encode the caseKey alongside the payload in the same object. The field name for the
    /// caseKey can be configured by the `caseField` argument. In this case, the paylaod must be
    /// either empty or object
    ///
    /// * Default caseKey: name of the enum case
    /// * Default payload with no associated value: ``EnumCaseCodingEmptyPayloadOption/nothing``
    /// * Default payload with associated values: ``EnumCaseCodingPayload/object``
    ///
    /// ```json
    /// {
    ///     <caseField>: <caseKey>,
    ///     payload
    /// }
    /// ```
    case internalKeyed(caseField: StaticString = "case")
    /// Encode only the payload as a single value
    ///
    /// During decoding, the matched case will be inferred by trying to match the encoded data
    /// with the specified payload value / structure of each enum case one-by-one. The first match
    /// will be picked
    ///
    /// The payload to be encoded is determined with the following rules in order:
    /// 1. If the enum case has associated values, use that as the payload
    /// 2. If the enum case has an specified rawValuePayload, use that as the payload
    /// 3. If the enum case has an native rawValue, use that as the payload
    /// 4. Otherwise use the name of the case as the payload
    ///
    /// ```json
    /// <payload>
    /// ```
    case unkeyed
    /// Encode the enum's raw value.
    ///
    /// This is only for enums that conforms to [`RawRepresentable`] and does not support any
    /// customization on the enum cases
    ///
    /// ```json
    /// <rawValue>
    /// ```
    ///
    /// [`RawRepresentable`]: https://developer.apple.com/documentation/swift/rawrepresentable
    case rawValueCoded
}



/// The type representing the caseKey for enum cases in encoding / decoding
///
/// It is basically an empty struct that support being constructed by String, Integer or Float
/// Literals. And also provide an ``EnumCaseCodingKey/auto`` static property used as the default
/// argument in the macro declaration.
///
/// > Attention:
/// > This type won't do anything, it's only used for declaraing ``EnumCaseCoding(caseKey:)`` macro
/// > without having to declare too many overloads
public struct EnumCaseCodingKey: Sendable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(stringLiteral value: StaticString) {}
    public init(integerLiteral value: Int) {}
    public init(floatLiteral value: Double) {}
    public static var auto: Self { 0 }
}



/// Options for representing an empty payload when encoding an enum case without associated values
///
/// Available Options:
/// * ``EnumCaseCodingEmptyPayloadOption/null``
/// * ``EnumCaseCodingEmptyPayloadOption/emptyObject``
/// * ``EnumCaseCodingEmptyPayloadOption/emptyArray``
/// * ``EnumCaseCodingEmptyPayloadOption/nothing``
public enum EnumCaseCodingEmptyPayloadOption: Sendable, Equatable {
    /// Represent an empty payload with an `null` literal
    case null
    /// Represent an empty payload with an empty object literal (e.g.: `{}` in json)
    case emptyObject
    /// Represent an empty paylaod with an empty array literal (e.g.: `[]` in json)
    case emptyArray
    /// Declare to not encode anything to represent an empty payload
    case nothing
}



/// Strategies for encoding associated values of enum cases
///
/// Available cases:
/// * ``EnumCaseCodingPayload/singleValue``
/// * ``EnumCaseCodingPayload/array``
/// * ``EnumCaseCodingPayload/object``
/// * ``EnumCaseCodingPayload/object(keys:)``
public enum EnumCaseCodingPayload: Sendable, Equatable {
    /// Encode a single associated value.
    /// Require the enum case to have exactly one associated value
    case singleValue
    /// Encode the associated values in an array in order
    case array
    /// Encode the associated values in an key-value object
    ///
    /// Without specifying custom key for each associated values, the key will be chosen as follow:
    /// * If the associated value has a label, use the label as the key
    /// * Otherwise, use "_i" as the key where `i` is the index of that associated value in
    ///   the declaration
    ///
    /// ```swift
    /// @EnumCodable
    /// enum Example {
    ///     case a(label1: Int, _: Int, Int, label2: Int)
    ///     // the keys will be: label1, _1, _2, label2
    /// }
    /// ```
    ///
    /// To customize the key used for each associated value, use
    /// ``EnumCaseCodingPayload/object(keys:)``
    ///
    /// > Attention:
    /// > The keys MUST NOT have duplication
    case object
    /// Encode the associated values in an key-value object using the provided keys for each
    /// associated values
    ///
    /// ```swift
    /// @EnumCodable
    /// enum Example {
    ///     @EnumCaseCoding(payload: .object(keys: "key1", "key2", "key3", "key4"))
    ///     case a(label1: Int, _: Int, Int, label2: Int)
    /// }
    /// ```
    ///
    /// > Attention:
    /// > The number of keys must be the same as the number of associated values
    ///
    /// > Attention:
    /// > The keys MUST NOT have duplication
    public static func object(keys: StaticString...) -> Self {
        return .object
    }
}
