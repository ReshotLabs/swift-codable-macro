//
//  SequenceCodingField.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Provide customization for a stored property whosed encoded form is a **Sequence** (e.g.: JSON Array)
/// when doing encoding and decoding
/// - Parameters:
///   - subPath: The coding path for fetching / storing the value in each of the element in the
///              encoded sequence
///   - elementEncodedType: The type that is actually stored as each element in the encoded sequence
///   - default: The default behaviour when an element that cannot be decoded corrected is met,
///              no matter the error is missing or mismatch
///
/// Setting the `default` parameter is the same as setting both `onMissing` and `onMismatch`
///
/// - Seealso: More detailed explaination can be found in
///          ``SequenceCodingField(subPath:elementEncodedType:onMissing:onMismatch:decodeTransform:encodeTransform:)``
@attached(peer)
public macro SequenceCodingField<E: Codable>(
    subPath: String...,
    elementEncodedType: E.Type,
    default: SequenceCodingFieldErrorStrategy<E>
) = #externalMacro(module: "CodableMacroMacros", type: "SequenceCodingFieldMacro")



/// Provide customization for a stored property whosed encoded form is a **Sequence** (e.g.: JSON Array)
/// when doing encoding and decoding
/// - Parameters:
///   - subPath: The coding path for fetching / storing the value in each of the element in the
///              encoded sequence
///   - elementEncodedType: The type that is actually stored as each element in the encoded sequence
///   - onMissing: The default behaviour when an element with missing coding path or `null` value
///                is met
///   - onMismatch: The default behaviour when an element with wrong type is met.
///
/// - Seealso: More detailed explaination can be found in
///          ``SequenceCodingField(subPath:elementEncodedType:onMissing:onMismatch:decodeTransform:encodeTransform:)``
@attached(peer)
public macro SequenceCodingField<E: Codable>(
    subPath: String...,
    elementEncodedType: E.Type,
    onMissing: SequenceCodingFieldErrorStrategy<E> = .throwError,
    onMismatch: SequenceCodingFieldErrorStrategy<E> = .throwError
) = #externalMacro(module: "CodableMacroMacros", type: "SequenceCodingFieldMacro")



/// Provide customization for a stored property whosed encoded form is a **Sequence** (e.g.: JSON Array)
/// when doing encoding and decoding
/// - Parameters:
///   - subPath: The coding path for fetching / storing the value in each of the element in the
///              encoded sequence
///   - elementEncodedType: The type that is actually stored as each element in the encoded sequence
///   - default: The default behaviour when an element that cannot be decoded corrected is met,
///              no matter the error is missing or mismatch
///   - decodeTransform: Convert the decoded raw array into the actual type. See the
///                      [Transformation and Element Encoded Type](#Transformation-and-Element-Encoded-Type)
///                      section for more details
///   - encodeTransform: Convert the value to be encoded into a sequence of elements for actual
///                      encoding. See the [Transformation and Element Encoded Type](#Transformation-and-Element-Encoded-Type)
///                      section for more details
///
/// Setting the `default` parameter is the same as setting both `onMissing` and `onMismatch`
///
/// - Seealso: More detailed explaination can be found in
///          ``SequenceCodingField(subPath:elementEncodedType:onMissing:onMismatch:decodeTransform:encodeTransform:)``
@attached(peer)
public macro SequenceCodingField<E: Codable, C, S: Sequence<E>>(
    subPath: String...,
    elementEncodedType: E.Type,
    default: SequenceCodingFieldErrorStrategy<E>,
    decodeTransform: ([E]) throws -> C,
    encodeTransform: (C) throws -> S
) = #externalMacro(module: "CodableMacroMacros", type: "SequenceCodingFieldMacro")



/// Provide customization for a stored property whosed encoded form is a **Sequence** (e.g.: JSON Array)
/// when doing encoding and decoding
/// - Parameters:
///   - subPath: The coding path for fetching / storing the value in each of the element in the
///              encoded sequence
///   - elementEncodedType: The type that is actually stored as each element in the encoded sequence
///   - default: The default behaviour when an element that cannot be decoded corrected is met,
///              no matter the error is missing or mismatch
///   - decodeTransform: Convert the decoded raw array into the actual type. See the
///                      [Transformation and Element Encoded Type](#Transformation-and-Element-Encoded-Type)
///                      section for more details
///
/// Setting the `default` parameter is the same as setting both `onMissing` and `onMismatch`
///
/// - Seealso: More detailed explaination can be found in
///          ``SequenceCodingField(subPath:elementEncodedType:onMissing:onMismatch:decodeTransform:encodeTransform:)``
@attached(peer)
public macro SequenceCodingField<E: Codable, C>(
    subPath: String...,
    elementEncodedType: E.Type,
    default: SequenceCodingFieldErrorStrategy<E>,
    decodeTransform: ([E]) throws -> C
) = #externalMacro(module: "CodableMacroMacros", type: "SequenceCodingFieldMacro")



/// Provide customization for a stored property whosed encoded form is a **Sequence** (e.g.: JSON Array)
/// when doing encoding and decoding
/// - Parameters:
///   - subPath: The coding path for fetching / storing the value in each of the element in the
///              encoded sequence
///   - elementEncodedType: The type that is actually stored as each element in the encoded sequence
///   - onMissing: The default behaviour when an element with missing coding path or `null` value
///                is met
///   - onMismatch: The default behaviour when an element with wrong type is met.
///   - decodeTransform: Convert the decoded raw array into the actual type. See the
///                      [Transformation and Element Encoded Type](#Transformation-and-Element-Encoded-Type)
///                      section for more details
///   - encodeTransform: Convert the value to be encoded into a sequence of elements for actual
///                      encoding. See the [Transformation and Element Encoded Type](#Transformation-and-Element-Encoded-Type)
///                      section for more details
///
/// ## Coding Path
///
/// This property decorator can be used together with ``CodingField(_:)``, where the `path` and the
/// `subPath` will be used together. The `path` in ``CodingField(_:)`` is responsible for locating
/// the sequence while the `subPath` is responsible for locating the data required inside each
/// element in the sequence. For example:
///
/// ```swift
/// @CodingField("path1", "a")
/// @SequenceCodingField(subPath: "inner", "value", elementEncodedType: Int.self)
/// var a: [Int]
/// ```
///
/// The property above represent the following JSON structure
///
/// ```json
/// {
///     "path1": {
///         "a": [
///             {
///                 "inner": { "value": 1 }
///             },
///             {
///                 "inner": { "value": 2 }
///             }
///         ]
///     }
/// }
/// ```
///
/// ## Default Behaviour
///
/// The `onMissing` and `onMismatch` parameters specify the bahaviour of the decoding process
/// when an elements that cannot be properly decoded is met
/// - `onMissing`: null value or missing coding path element
/// - `onMismatch` incorrect type
///
/// The behaviour can be:
/// * ``SequenceCodingFieldErrorStrategy/throwError``: Abort the decoding process and throw a
///   [`DecodingError`] (the default value specified in ``CodingField(_:default:)`` or
///   ``CodingField(_:onMissing:onMismatch:)`` still takes effect
/// * ``SequenceCodingFieldErrorStrategy/ignore``: Skip the failed element and continue the
///   decoding process
/// * ``SequenceCodingFieldErrorStrategy/value(_:)``: Apply an default value and continue the
///   decoding process
///
/// The default value for both of them are ``SequenceCodingFieldErrorStrategy/throwError``
///
/// ## Transformation and Element Encoded Type
///
/// When decoding, it always try to decode each elements into the type specified by the
/// `elementEncodedType` and form an Array of that type. Then the `decodeTransform` closure will
/// be invoked with this array for converting it into desired type.
///
/// This transformation will be called before any other transformation specified by
/// ``DecodeTransform(source:target:with:)`` and ``CodingTransform(_:)``. If it is not provided,
/// then it assume that the desired type is Array of `elementEncodedType`.
///
/// When encoding, the `encodeTransform` closure is first invoked to convert the value into a
/// sequence of `elementEncodedType`. It does not have to be an Array, an [`Sequence`] is enough.
///
/// This transformation will be called after any other transformation specified by
/// ``EncodeTransform(source:target:with:)`` and ``CodingTransform(_:)``. If it is not provided,
/// then it assume that the value to be encoded is already an sequence of `elementEncodedType`
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
///
/// - Attention: Just like the rule for ``CodingField(_:)``, any two stored properties in a type
/// MUST NOT have conflict coding path. However, here the coding path will be the concatenated
/// path from both ``CodingField(_:)`` and this macro.
///
/// - Attention: Must be used together with ``Codable(inherit:)``
///
/// - Seealso: ``CodingField(_:)``
///
/// [`DecodingError`]: https://developer.apple.com/documentation/swift/decodingerror
/// [`Sequence`]: https://developer.apple.com/documentation/swift/sequence
@attached(peer)
public macro SequenceCodingField<E: Codable, C, S: Sequence<E>>(
    subPath: String...,
    elementEncodedType: E.Type,
    onMissing: SequenceCodingFieldErrorStrategy<E> = .throwError,
    onMismatch: SequenceCodingFieldErrorStrategy<E> = .throwError,
    decodeTransform: ([E]) throws -> C,
    encodeTransform: (C) throws -> S
) = #externalMacro(module: "CodableMacroMacros", type: "SequenceCodingFieldMacro")



/// Provide customization for a stored property whosed encoded form is a **Sequence** (e.g.: JSON Array)
/// when doing encoding and decoding
/// - Parameters:
///   - subPath: The coding path for fetching / storing the value in each of the element in the
///              encoded sequence
///   - elementEncodedType: The type that is actually stored as each element in the encoded sequence
///   - onMissing: The default behaviour when an element with missing coding path or `null` value
///                is met
///   - onMismatch: The default behaviour when an element with wrong type is met.
///   - decodeTransform: Convert the decoded raw array into the actual type. See the
///                      [Transformation and Element Encoded Type](#Transformation-and-Element-Encoded-Type)
///                      section for more details
///
/// - Seealso: More detailed explaination can be found in
///            ``SequenceCodingField(subPath:elementEncodedType:onMissing:onMismatch:decodeTransform:encodeTransform:)``
@attached(peer)
public macro SequenceCodingField<E: Codable, C>(
    subPath: String...,
    elementEncodedType: E.Type,
    onMissing: SequenceCodingFieldErrorStrategy<E> = .throwError,
    onMismatch: SequenceCodingFieldErrorStrategy<E> = .throwError,
    decodeTransform: ([E]) throws -> C
) = #externalMacro(module: "CodableMacroMacros", type: "SequenceCodingFieldMacro")
