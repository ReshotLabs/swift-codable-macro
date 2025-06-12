//
//  EnumCodableMacros.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Automatically make the annotated `enum` conform to [`Codable`] by generating encoding and
/// decoding logic for all cases.
///
/// - Parameter option: The coding style for the enum. See ``EnumCodableOption`` for details.
///
/// # Coding Format
///
/// The format for encoding enum is not standardized, so ``EnumCodable(option:)`` provide several
/// common format options controlled by the `option` argument. There are two big types of formats,
/// Keyed Format and Unkeyed Format
///
/// ### Keyed Format
/// Considere each enum case to have 2 parts:
/// * caseKey: Identify which enum case it is. Can be String, Int or Float
/// * payload: Additional information, usually for associated values. For cases without associated
///            values, it can be some placeholder such as `null` or `{}` in json. In some special
///            cases, payload itself can also be used to identify different enum cases. See more
///            about payload in ``EnumCaseCodingPayload`` and ``EnumCaseCodingEmptyPayloadOption``
///
/// - Attention: the `caseKey` of each case must be unique
///
/// The following coding format are provided as Keyed Format
///
/// **``EnumCodableOption/externalKeyed``**:
///
/// Encode as an object where the key is the caseKey and the value is the payload. In this case,
/// caseKey must be string and payload cannot be ``EnumCaseCodingEmptyPayloadOption/nothing``
/// * Default caseKey: name of the enum case
/// * Default payload with no associated value: ``EnumCaseCodingEmptyPayloadOption/emptyObject``
/// * Default payload with single associated value: ``EnumCaseCodingPayload/singleValue``
/// * Default payload with multiple associated values: ``EnumCaseCodingPayload/object``
///
/// ```json
/// {
///     "<caseKey>": <payload>
/// }
/// ```
///
/// **``EnumCodableOption/adjucentKeyed(caseField:payloadField:)``**:
///
/// Encode as an object with separated fields for caseKey and payload. The field names can be
/// configured by the `caseField` and the `payloadField` arguments.
/// * Default caseKey: name of the enum case
/// * Default payload with no associated value: ``EnumCaseCodingEmptyPayloadOption/null``
/// * Default payload with single associated value: ``EnumCaseCodingPayload/singleValue``
/// * Default payload with multiple associated values: ``EnumCaseCodingPayload/object``
///
///   ```json
///   {
///       "<caseField>": <caseKey>,
///       "<payloadField>": <payload>
///   }
///   ```
///
/// **``EnumCodableOption/internalKeyed(caseField:)``**:
///
/// Encode the caseKey alongside the payload in the same object. The field name for the caseKey can
/// be configured by the `caseField` argument. In this case, the paylaod must be either empty
/// or object
/// * Default caseKey: name of the enum case
/// * Default payload with no associated value: ``EnumCaseCodingEmptyPayloadOption/nothing``
/// * Default payload with associated values: ``EnumCaseCodingPayload/object``
///
/// ```json
/// {
///     "<caseField>": <caseKey>,
///     <payload>
/// }
/// ```
///
/// ### Unkeyed Format
/// Associate each enum case to a certain structure / value and identify cases by data
/// structure / value without explicitly storing the caseKey. Usually require one-by-one matching
/// to identify the cases.
///
/// - Attention: The structure / value should be unique. The macro will try to identify potential
/// conflicts, but there is **NO** guarantee to find all the errors.
///
/// **``EnumCodableOption/unkeyed``**:
///
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
/// ```json
/// <payload>
/// ```
///
/// **``EnumCodableOption/rawValueCoded``**:
///
/// Encode the enum's raw value. This is only for enums that conforms to [`RawRepresentable`]
/// and does not support any customization on the enum cases
/// ```json
/// <rawValue>
/// ```
///
/// - Note: When no coding format is specified, ``EnumCodableOption/unkeyed`` is used if the enum
///   includes native rawValue and ``EnumCodableOption/externalKeyed`` is used otherwise.
///
/// # Customizing Case Keys and Payloads
///
/// Use `@EnumCaseCoding` macro for per-case customization
///
/// ### For Keyed Format
///
/// * ``EnumCaseCoding(caseKey:payload:)``: Specify the caseKey and how to encode the associated
/// values as the payload for a enum case. The enum case must contains at least one associated value.
/// * ``EnumCaseCoding(caseKey:emptyPayloadOption:)``: Specify the caseKey and mode for representing
/// an empty payload. The enum case must have no associated value
///
/// ### For Unkeyed Format
///
/// * ``EnumCaseCoding(unkeyedRawValuePayload:type:)``: Specify the rawValuePayload for the enum
///   case . The type can be anything that conforms to [`Codable`] and either
///   [`ExpressibleByStringLiteral`], [`ExpressibleByIntegerLiteral`] or
///   [`ExpressibleByFloatLiteral`]. The enum case must have no associated value.
/// * ``EnumCaseCoding(unkeyedPayload:)``: Specify how to encode the associated values as the
///   payload for a enum case. The enum case must have at least one associated value.
///
/// # Default Value
///
/// By default, if fail to find a matching enum case for the given encoded data, a [`typemismatch`]
/// error will be thrown. You can specify an default value in the
/// ``EnumCodableProtocol/codingDefaultValue`` static member, which will be used when no matching
/// enum case can be found.
///
/// ```swift
/// @EnumCodable
/// enum Test {
///     case a, b
///     static let codingDefaultValue: Self? = .a
/// }
/// ```
///
/// [`Codable`]: https://developer.apple.com/documentation/swift/codable
/// [`RawRepresentable`]: https://developer.apple.com/documentation/swift/rawrepresentable
/// [`ExpressibleByStringLiteral`]: https://developer.apple.com/documentation/swift/expressiblebystringliteral
/// [`ExpressibleByIntegerLiteral`]: https://developer.apple.com/documentation/swift/expressiblebyintegerliteral
/// [`ExpressibleByFloatLiteral`]: https://developer.apple.com/documentation/swift/expressiblebyfloatliteral
/// [`typemismatch`]: https://developer.apple.com/documentation/swift/decodingerror/typemismatch(_:_:)
@attached(extension, conformances: EnumCodableProtocol, names: arbitrary)
@attached(member, names: arbitrary)
public macro EnumCodable(option: EnumCodableOption) = #externalMacro(module: "CodableMacroMacros", type: "EnumCodableMacro")


/// Automatically make the annotated enum conform to [`Codable`] by generating encoding and
/// decoding logic for all cases.
///
/// Same as ``EnumCodable(option:)``, with the `option` being inferred automatically
/// * If the attached enum has native rawValue, use ``EnumCodableOption/unkeyed``
/// * Otherwise, use ``EnumCodableOption/externalKeyed``
///
/// - Seealso: ``EnumCodable(option:)``
///
/// [`Codable`]: https://developer.apple.com/documentation/swift/codable
@attached(extension, conformances: EnumCodableProtocol, names: arbitrary)
@attached(member, names: arbitrary)
public macro EnumCodable() = #externalMacro(module: "CodableMacroMacros", type: "EnumCodableMacro")
