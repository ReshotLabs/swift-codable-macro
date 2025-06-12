//
//  EnumCaseCoding.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Provide customization for the behaviour of an enum case without associated value when
/// encoding/decoding by specifying the caseKey and how to represent an empty payload
///
/// - Parameter caseKey: The identifier of this enum case when encoding/decoding.
///                      Defaults to `.auto`, which uses the case name.
/// - Parameter emptyPayloadOption: Specifies how to represent an empty payload (for cases without
///                                 associated values), such as `null`, `{}`, or nothing.
///                                 See ``EnumCaseCodingEmptyPayloadOption`` for details.
///
/// Use this macro on enum cases without associated values to customize their caseKey and the way
/// of representing the empty payload
///
/// ```swift
/// @EnumCodable
/// enum Example {
///     @EnumCaseCoding(caseKey: "a_key", emptyPayloadOption: .null)
///     case a
///     @EnumCaseCoding(emptyPayloadOption: .emptyObject)
///     case b
/// }
/// ```
///
/// Some rules related to coding format when using this macro:
/// * When the coding format is ``EnumCodableOption/externalKeyed``, the `key` MUST be string and
///   the `emptyPayloadOption` CANNOT be ``EnumCaseCodingEmptyPayloadOption/nothing``
/// * When the coding format is ``EnumCodableOption/internalKeyed(caseField:)``, the
///   `emptyPayloadOption` MUST be ``EnumCaseCodingEmptyPayloadOption/nothing``
/// * Cannot be used when the coding format is Unkeyed format, including
///   ``EnumCodableOption/unkeyed`` and ``EnumCodableOption/rawValueCoded``
///
/// - Attention: Can only be used on enum cases without associated values.
/// - Attention: Only effective when used within enums annotated with ``EnumCodable(option:)``
@attached(peer)
public macro EnumCaseCoding(caseKey: EnumCaseCodingKey = .auto, emptyPayloadOption: EnumCaseCodingEmptyPayloadOption) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


/// Provide customization for the behaviour of an enum case with associated values when
/// encoding/decoding by specifying the caseKey and how to encode the associated values as the payload.
///
/// - Parameter caseKey: The identifier of this enum case when encoding/decoding.
///                      Defaults to `.auto`, which uses the case name.
/// - Parameter payload: Specifies how to encode the associated values for this case. See
///                      ``EnumCaseCodingPayload`` for available strategies.
///
/// Use this macro on enum cases with associated values to customize their caseKey and the way the
/// associated values are represented in the encoded payload.
///
/// ```swift
/// @EnumCodable
/// enum Example {
///     @EnumCaseCoding(caseKey: "custom_case", payload: .object(keys: "x1", "x2"))
///     case a(x: Int, _: String)
///     @EnumCaseCoding(payload: .singleValue)
///     case b(value: Double)
///     @EnumCaseCoding(payload: .array)
///     case c(Int, String)
/// }
/// ```
///
/// Some rules related to coding format when using this macro:
/// * When the coding format is ``EnumCodableOption/externalKeyed``, the `key` MUST be string.
/// * When the coding format is ``EnumCodableOption/internalKeyed(caseField:)``, the payload MUST
///   be an object.
/// * Cannot be used when the coding format is Unkeyed format, including
///   ``EnumCodableOption/unkeyed`` and ``EnumCodableOption/rawValueCoded``
///
///
/// > Attention:
/// > Can only be used on enum cases with associated values.
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
@attached(peer)
public macro EnumCaseCoding(caseKey: EnumCaseCodingKey = .auto, payload: EnumCaseCodingPayload) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


/// Provide customization for the behaviour of an enum case when encoding/decoding by specifying
/// the caseKey and the paylaod / emptyPayloadOption will be inferred automatically
///
/// - Parameter caseKey: The identifier of this enum case when encoding/decoding.
///
/// Use this macro on enum cases with or without associated values to customize their caseKey. The
/// payload / emptyPayloadOption in this case will be inferred automatically:
///
/// | Coding Format | Associated Values | payload / emptyPayloadOption |
/// | --- | :---: | :---: |
/// | ``EnumCodableOption/externalKeyed`` , <br>``EnumCodableOption/adjucentKeyed(caseField:payloadField:)`` | no | ``EnumCaseCodingEmptyPayloadOption/null`` |
/// | ^ | single | ``EnumCaseCodingPayload/singleValue`` |
/// | ^ | multiple | ``EnumCaseCodingPayload/object`` |
/// | ``EnumCodableOption/internalKeyed(caseField:)`` | no | ``EnumCaseCodingEmptyPayloadOption/nothing`` |
/// | ^ | any | ``EnumCaseCodingPayload/object`` |
///
/// ```swift
/// @EnumCodable(option: .adjucentKeyed)
/// enum Example {
///     @EnumCaseCoding(caseKey: "key_a")
///     case a
///     @EnumCaseCoding(caseKey: 1)
///     case b
///     @EnumCaseCoding(caseKey: 2.2)
///     case c
/// }
/// ```
///
/// Some rules related to coding format when using this macro:
/// * When the coding format is ``EnumCodableOption/externalKeyed``, the `key` MUST be string.
/// * Cannot be used when the coding format is Unkeyed format, including
///   ``EnumCodableOption/unkeyed`` and ``EnumCodableOption/rawValueCoded``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
@attached(peer)
public macro EnumCaseCoding(caseKey: EnumCaseCodingKey) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


/// Provide customization for the behaviour of an enum case without associated values when
/// encoding/decoding by specifying a rawValue payload as a String.
///
/// - Parameter unkeyedRawValuePayload: the String rawValue that will be encoded for this case
///
/// Use this macro on enum cases without associated values to customize the String rawValue that
/// will be encoded to represent this case.
/// * When encoding, this specified rawValue will be encoded
/// * When decoding, compare the decoded value with this specified rawValue. If matched, then
///   this case will be picked as the decod result
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: StaticString) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


/// Provide customization for the behaviour of an enum case without associated values when
/// encoding/decoding by specifying a rawValue payload as a curtom type that conforms to
/// [`ExpressibleByStringLiteral`].
///
/// - Parameter unkeyedRawValuePayload: the rawValue as a String literal that will be encoded
///                                     for this case
/// - Parameter type: the type of the rawValue
///
/// Use this macro on enum cases without associated values to customize the rawValue that
/// will be encoded to represent this case. The type of the rawValue must conforms to
/// [`ExpressibleByStringLiteral`] and the value must be specified using a String literal
/// * When encoding, this specified rawValue will be encoded
/// * When decoding, compare the decoded value with this specified rawValue. If matched, then
///   this case will be picked as the decod result
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
///
/// [`ExpressibleByStringLiteral`]: https://developer.apple.com/documentation/swift/expressiblebystringliteral
@attached(peer)
public macro EnumCaseCoding<T>(unkeyedRawValuePayload: StaticString, type: T.Type) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")
where T: ExpressibleByStringLiteral, T: Codable, T: Equatable


/// Provide customization for the behaviour of an enum case without associated values when
/// encoding/decoding by specifying a rawValue payload as a Integer.
///
/// - Parameter unkeyedRawValuePayload: the Integer rawValue that will be encoded for this case
///
/// Use this macro on enum cases without associated values to customize the Integer rawValue that
/// will be encoded to represent this case.
/// * When encoding, this specified rawValue will be encoded
/// * When decoding, compare the decoded value with this specified rawValue. If matched, then
///   this case will be picked as the decod result
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: StaticBigInt) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


/// Provide customization for the behaviour of an enum case without associated values when
/// encoding/decoding by specifying a rawValue payload as a Integer.
///
/// - Parameter unkeyedRawValuePayload: the Integer rawValue that will be encoded for this case
///
/// Use this macro on enum cases without associated values to customize the Integer rawValue that
/// will be encoded to represent this case.
/// * When encoding, this specified rawValue will be encoded
/// * When decoding, compare the decoded value with this specified rawValue. If matched, then
///   this case will be picked as the decod result
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: Int) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


/// Provide customization for the behaviour of an enum case without associated values when
/// encoding/decoding by specifying a rawValue payload as a curtom type that conforms to
/// [`ExpressibleByIntegerLiteral`].
///
/// - Parameter unkeyedRawValuePayload: the rawValue as a Integer literal that will be encoded
///                                     for this case
/// - Parameter type: the type of the rawValue
///
/// Use this macro on enum cases without associated values to customize the rawValue that
/// will be encoded to represent this case. The type of the rawValue must conforms to
/// [`ExpressibleByIntegerLiteral`] and the value must be specified using a Integer literal
/// * When encoding, this specified rawValue will be encoded
/// * When decoding, compare the decoded value with this specified rawValue. If matched, then
///   this case will be picked as the decod result
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
///
/// [`ExpressibleByIntegerLiteral`]: https://developer.apple.com/documentation/swift/expressiblebyintegerliteral
@attached(peer)
public macro EnumCaseCoding<T>(unkeyedRawValuePayload: T.IntegerLiteralType, type: T.Type) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")
where T: ExpressibleByIntegerLiteral, T: Codable, T: Equatable


/// Provide customization for the behaviour of an enum case without associated values when
/// encoding/decoding by specifying a rawValue payload as a Float.
///
/// - Parameter unkeyedRawValuePayload: the Float rawValue that will be encoded for this case
///
/// Use this macro on enum cases without associated values to customize the Float rawValue that
/// will be encoded to represent this case.
/// * When encoding, this specified rawValue will be encoded
/// * When decoding, compare the decoded value with this specified rawValue. If matched, then
///   this case will be picked as the decod result
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: Double) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


/// Provide customization for the behaviour of an enum case without associated values when
/// encoding/decoding by specifying a rawValue payload as a curtom type that conforms to
/// [`ExpressibleByFloatLiteral`].
///
/// - Parameter unkeyedRawValuePayload: the rawValue as a Float literal that will be encoded
///                                     for this case
/// - Parameter type: the type of the rawValue
///
/// Use this macro on enum cases without associated values to customize the rawValue that
/// will be encoded to represent this case. The type of the rawValue must conforms to
/// [`ExpressibleByFloatLiteral`] and the value must be specified using a Float literal
/// * When encoding, this specified rawValue will be encoded
/// * When decoding, compare the decoded value with this specified rawValue. If matched, then
///   this case will be picked as the decod result
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
///
/// [`ExpressibleByFloatLiteral`]: https://developer.apple.com/documentation/swift/expressiblebyfloatliteral
@attached(peer)
public macro EnumCaseCoding<T>(unkeyedRawValuePayload: T.FloatLiteralType, type: T.Type) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")
where T: ExpressibleByFloatLiteral, T: Codable, T: Equatable


/// Provide customization for the behaviour of an enum case with associated values when
/// encoding/decoding by specifying the strategy of encoding its associated values as the payload
///
/// - Parameter unkeyedPayload: the strategy of encoding the associated values, see
///                             ``EnumCaseCodingPayload`` for more info
///
/// Use this macro on enum cases with associated values to customize the how its associated values
/// will be encoded to represent this case.
/// * When encoding, the associated values of the enum case will be encoded directly base on the
///   specified strategy
/// * When decoding, it will try to deocode all the associated values of this enum case base on
///   the specified strategy. If success, this enum case will be picked as the decode result and
///   the decoded associated values will be assigned.
///
/// > Attention:
/// > Can only be used when the coding format is ``EnumCodableOption/unkeyed``
///
/// > Attention:
/// > Only effective when used within enums annotated with ``EnumCodable(option:)``
@attached(peer)
public macro EnumCaseCoding(unkeyedPayload: EnumCaseCodingPayload) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")
