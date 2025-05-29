// The Swift Programming Language
// https://docs.swift.org/swift-book


// MARK: Codable


/// Automatically make the marked `class` or `struct` to conform to [`Codable`]
/// - Parameter inherit: Whether this class has an super class that has already conformed to [`Codable`]
///
/// When being expanded, it will look up all the stored properties and automatically generate
/// the implementation of [`encode(to:)`] and [`init(from:)`]
///
/// * As long as a property is not marked as ``CodingIgnore()``, it will be considered in the
/// implementation
/// * Optional and default value will be considered when decoding
///
/// You can specifi a custom coding path and a default value using ``CodingField(_:)``
/// or ``CodingField(_:default:)`` macros.
///
/// A coding path is a sequence of coding keys for finding
/// a value in the encoded data. For example, consider the following json string:
///
/// ```json
/// {
///     "meta": {
///         "name": "Serika",
///         "age": 15
///     }
/// }
/// ```
///
/// The coding path of `"name"` is `["meta", "name"]`
///
/// An example usable is as follow:
///
/// ```swift
/// @Codable
/// class Test {
///     var field1: String
///     var field2: String?
///     var field3: String = "default"
///     @CodingField("path1", "field4")
///     var field4: String
///     @CodingField("path1", "field5")
///     var field5: String?
///     @CodingField("path1", "field6")
///     var field6: String = "default"
///     @CodingField("path1", "field7", default: "default")
///     var field7: String
/// }
/// ```
///
/// Here for property `field6`, the default value "field6" will suppress "default" when decoding
///
/// - Note: If none of the stored property has actual customization (i.e.: have a custom coding
/// path or default value specified by ``CodingField(_:)`` or marked with ``CodingIgnore()``),
/// then the auto implementation will be delegated to the Swift Compiler
///
/// - Attention: If a stored property is a let constant with an initializer, it will still be included
/// when doing encoding, but will be ignored in decoding (i.e.: the value in the encoded data will
/// not take effect). To specify a default value for a let constant, use ``CodingField(_:default:)``
/// instead of using an initializer
///
/// [`Codable`]: https://developer.apple.com/documentation/swift/codable
/// [`encode(to:)`]: https://developer.apple.com/documentation/swift/encodable/encode(to:)-7ibwv
/// [`init(from:)`]: https://developer.apple.com/documentation/swift/decodable/init(from:)-8ezpn
@attached(extension, conformances: Codable, names: arbitrary)
@attached(member, names: arbitrary)
public macro Codable(inherit: Bool = false) = #externalMacro(module: "CodableMacroMacros", type: "CodableMacro")



// MARK: CodingField


/// Provide customization for a stored property when doing encoding and decoding
/// - Parameter path: The coding path for fetching / storing the value in the encoded data
/// - Parameter default: The default value to use when any error occurs when decoding that field, 
///                      including value missing and type mismatch 
///
/// * When the `path` parameter is not specified, the name of the property will be used
/// * Stored properties without any of ``CodingField(_:)``, ``CodingField(_:default:)``
/// and ``CodingIgnore()`` will be treated as being anotated with `@CodingField`
/// * If both initializer and the `default` argument is provided, the `default` argument will
/// suppress the initializer when decoding
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
///
/// - Attention: Any two stored properties in a type MUST NOT have conflict coding path. Path `A`
/// and path `B` are conflicted if `A` is exactly the same as `B` or `A` is a prefix of `B` or vice versa
///
/// - Attention: Must be used together with ``Codable()``
@attached(peer)
public macro CodingField<T>(_ path: String..., default: T) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")



/// Provide customization for a stored property when doing encoding and decoding
/// - Parameter path: The coding path for fetching / storing the value in the encoded data
/// - Parameter onMissing: The default value to use when the required coding path is missing in the encoded data
///
/// * When the `path` parameter is not specified, the name of the property will be used
/// * Stored properties without any of ``CodingField(_:)``, ``CodingField(_:default:)``
/// and ``CodingIgnore()`` will be treated as being anotated with `@CodingField`
/// * If both initializer and the `default` argument is provided, the `default` argument will
/// suppress the initializer when decoding
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
///
/// - Attention: Any two stored properties in a type MUST NOT have conflict coding path. Path `A`
/// and path `B` are conflicted if `A` is exactly the same as `B` or `A` is a prefix of `B` or vice versa
///
/// - Attention: Must be used together with ``Codable()``
@attached(peer)
public macro CodingField<T>(_ path: String..., onMissing: T) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")



/// Provide customization for a stored property when doing encoding and decoding
/// - Parameter path: The coding path for fetching / storing the value in the encoded data
/// - Parameter onMismatch: The default value to use when the value has wrong type the encoded data
///
/// * When the `path` parameter is not specified, the name of the property will be used
/// * Stored properties without any of ``CodingField(_:)``, ``CodingField(_:default:)``
/// and ``CodingIgnore()`` will be treated as being anotated with `@CodingField`
/// * If both initializer and the `default` argument is provided, the `default` argument will
/// suppress the initializer when decoding
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
///
/// - Attention: Any two stored properties in a type MUST NOT have conflict coding path. Path `A`
/// and path `B` are conflicted if `A` is exactly the same as `B` or `A` is a prefix of `B` or vice versa
///
/// - Attention: Must be used together with ``Codable()``
@attached(peer)
public macro CodingField<T>(_ path: String..., onMismatch: T) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")



/// Provide customization for a stored property when doing encoding and decoding
/// - Parameter path: The coding path for fetching / storing the value in the encoded data
/// - Parameter onMissing: The default value to use when the required coding path is missing in the encoded data
/// - Parameter onMismatch: The default value to use when the value has wrong type the encoded data
///
/// * When the `path` parameter is not specified, the name of the property will be used
/// * Stored properties without any of ``CodingField(_:)``, ``CodingField(_:default:)``
/// and ``CodingIgnore()`` will be treated as being anotated with `@CodingField`
/// * If both initializer and the `default` argument is provided, the `default` argument will
/// suppress the initializer when decoding
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
///
/// - Attention: Any two stored properties in a type MUST NOT have conflict coding path. Path `A`
/// and path `B` are conflicted if `A` is exactly the same as `B` or `A` is a prefix of `B` or vice versa
///
/// - Attention: Must be used together with ``Codable()``
@attached(peer)
public macro CodingField<T>(_ path: String..., onMissing: T, onMismatch: T) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")



/// Provide customization for a stored property when doing encoding and decoding
/// - Parameter path: The coding path for fetching / storing the value in the encoded data
///
/// * When the `path` parameter is not specified, the name of the property will be used
/// * Stored properties without any of ``CodingField(_:)``, ``CodingField(_:default:)``
/// and ``CodingIgnore()`` will be treated as being anotated with `@CodingField`
/// * If the stored property has an initializer, it will be considered when decoding
/// * If the stored property is optional without initializer, it is the same as having a
/// default value of `nil`
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
///
/// - Attention: This macro is not smart enough to identify optional properties that are
/// not defined with `?` mark. So PLEASE use `?` only for optional properties
///
/// - Attention: Any two stored properties in a type MUST NOT have conflict coding path. Path `A`
/// and path `B` are conflicted if `A` is exactly the same as `B` or `A` is a prefix of `B` or vice versa
///
/// - Attention: Must be used together with ``Codable(inherit:)``
@attached(peer)
public macro CodingField(_ path: String...) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")



// MARK: SequenceCodingField


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



// MARK: CodingIgnore


/// Mark a stored property to be ignored when doing encoding and decoding
///
/// - Attention: The stored property MUST be optional or have a initializer
@attached(peer)
public macro CodingIgnore() = #externalMacro(module: "CodableMacroMacros", type: "CodingIgnoreMacro")



// MARK: DecodeTransform


/// Provide a transformation rule when decoding for a stored property
///
/// First decode the value as the `sourceType`, then apply the transformation to convert
/// to the type of the property
///
/// ```swift
/// @DecodeTransform(source: String.self, with: { UUID(uuidString: $0)! })
/// var id: UUID
/// ```
///
/// - Attention: ONLY when the process of decoding the value as the `sourceType` success that
/// the transformation will be invoked
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
@attached(peer)
public macro DecodeTransform<Source: Decodable, Target>(
    source sourceType: Source.Type,
    target targetType: Target.Type = Target.self,
    with transform: @escaping (Source) throws -> Target
) = #externalMacro(module: "CodableMacroMacros", type: "DecodeTransformMacro")



// MARK: EncodeTransform


/// Provide a transformation rule when encoding a stored property
///
/// First convert the value of the property using the transformation, then encode
/// the converted value
///
/// ```swift
/// @EncodeTransform(source: UUID.self, with: \.uuidString)
/// var id: UUID
/// ```
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
@attached(peer)
public macro EncodeTransform<Source, Target: Encodable>(
    source sourceType: Source.Type,
    target targetType: Target.Type = Target.self,
    with transform: @escaping (Source) throws -> Target
) = #externalMacro(module: "CodableMacroMacros", type: "EncodeTransformMacro")



// MARK: CodingTransform


/// Provide custom transformers used for both encoding and decoding
///
/// The transformers must conforms to ``CodingTransformProtocol``, which provide rules of
/// transformation for encoding and decoding.
///
/// You can specify multiple transformers and their order matters:
/// * Encode: in order (from first to last)
/// * Decode: reversed order (from last to first)
///
/// ```swift
/// @Codable
/// struct Test {
///     @CodingTransform(
///         .doubleDateTransform,
///         .doubleTypeTransform(option: .string)
///     )
///     var a: Date
/// }
/// ```
///
/// In this example:
/// * For encoding, first use the `.doubleDateTransform` to convert `Date` to `Double`, then use
/// the `.doubleTypeTransform(option: .string)` to convert `Double` to `String`
/// * For decoding, first use the `.doubleTypeTransform(option: .string)` to convert `String`
/// to `Double`, then use the `.doubleDateTransform` to convert `Double` to `Date`
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
@attached(peer)
public macro CodingTransform<each Transformer: EvenCodingTransformProtocol>(
    _ transformers: repeat each Transformer
) = #externalMacro(module: "CodableMacroMacros", type: "CodingTransformMacro")



// MARK: CodingValidate


/// Provide a validation rule when decoding for a stored property
///
/// If the property is neigher optional nor has an default value, an error will be thrown,
/// otherwise `nil` or the default value will be used.
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
@attached(peer)
public macro CodingValidate<Source: Decodable>(
    source sourceType: Source.Type,
    with validate: @escaping (Source) throws -> Bool
) = #externalMacro(module: "CodableMacroMacros", type: "CodingValidateMacro")



// MARK: SingleValueCodable


/// Automatically make the annotated `class` or `struct` to conform to [`Codable`] by converting
/// instances from/to instances of another type.
/// - Parameter inherit: Whether this class has an super class that has already conformed to [`Codable`]
///
/// What this macro does is simply conform the type to ``SingleValueCodableProtocol``, which
/// has already provided the implementation of [`encode(to:)`] and [`init(from:)`], but requires
/// implementation of:
/// * ``SingleValueCodableProtocol/singleValueEncode()``: Convert the instance to an
/// instance of another type that will actually be encoded.
/// * ``SingleValueCodableProtocol/init(from:)``: Create an instance of this type using an
/// instance of another type being decoded.
/// 
/// If `inherit` is set to `true`, then it will conform to ``InheritedSingleValueCodableProtocol``,
/// which requires implementing:
/// * ``InheritedSingleValueCodableProtocol/singleValueEncode()``: Convert the instance
/// to an instance of another type that will actually be encoded.
/// * ``InheritedSingleValueCodableProtocol/init(from:decoder:)``: Create an instance of this type using
/// an instance of another type being decoded. The `decoder` parameter is used for calling `super.init(from:)`
///
/// ```swift
/// @SingleValueCodable
/// struct Test {
///     var a: Int
///     func singleValueEncode() throws -> String {
///         self.a.description
///     }
///     init(from codingValue: String) throws {
///         self.a = .init(codingValue)!
///     }
/// }
/// ```
///
/// If only one property in the type is directly responsible for the encoding and decoding process,
/// then simply annotate that property with the ``SingleValueCodableDelegate()`` macro without
/// having to manually implement the two functions above. An example is as follow.
///
/// ```swift
/// // if your implementation looks like this
/// @SingleValueCodable
/// struct Test {
///     var a: Int
///     var b: String = "b"
///     func singleValueEncode() throws -> Int { self.a }
///     init(from codingValue: String) throws {
///         self.a = codingValue
///     }
/// }
///
/// // then it can be re-written as follow
/// @SingleValueCodable
/// struct Test {
///     @SingleValueCodableDelegate
///     var a: Int
///     var b: String = "b"
/// }
/// ```
///
/// [`Codable`]: https://developer.apple.com/documentation/swift/codable
/// [`encode(to:)`]: https://developer.apple.com/documentation/swift/encodable/encode(to:)-7ibwv
/// [`init(from:)`]: https://developer.apple.com/documentation/swift/decodable/init(from:)-8ezpn
@attached(member, names: arbitrary)
@attached(extension, conformances: InheritedSingleValueCodableProtocol, SingleValueCodableProtocol, names: arbitrary)
public macro SingleValueCodable(inherit: Bool = false) = #externalMacro(module: "CodableMacroMacros", type: "SingleValueCodableMacro")



// MARK: SingleValueCodableDelegate


/// Annotate a stored property as the only property responsible for the encoding and decoding
/// process.
///
/// - Seealso: More detailed explaination can be found in ``SingleValueCodableDelegate(default:)``
@attached(peer)
public macro SingleValueCodableDelegate() = #externalMacro(module: "CodableMacroMacros", type: "SingleValueCodableDelegateMacro")



/// Annotate a stored property as the only property responsible for the encoding and decoding
/// process.
/// - Parameter default: The default value to use when the decoding process fails
///
/// The following two definitions are identical:
/// ```swift
/// @SingleValueCodable
/// struct Test {
///     @SingleValueCodableDelegate
///     var a: Int
///     var b: String = "b"
/// }
///
/// @SingleValueCodable
/// struct Test {
///     var a: Int
///     var b: String = "b"
///     func singleValueEncode() throws -> Int { self.a }
///     init(from codingValue: String) throws {
///         self.a = codingValue
///     }
/// }
/// ```
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
@attached(peer)
public macro SingleValueCodableDelegate<T>(default: T) = #externalMacro(module: "CodableMacroMacros", type: "SingleValueCodableDelegateMacro")



// MARK: EnumCodable


@attached(extension, conformances: EnumCodableProtocol, names: arbitrary)
@attached(member, names: arbitrary)
public macro EnumCodable(option: EnumCodableOption) = #externalMacro(module: "CodableMacroMacros", type: "EnumCodableMacro")



@attached(extension, conformances: EnumCodableProtocol, names: arbitrary)
@attached(member, names: arbitrary)
public macro EnumCodable() = #externalMacro(module: "CodableMacroMacros", type: "EnumCodableMacro")



// MARK: EnumCaseCoding


@attached(peer)
public macro EnumCaseCoding(key: EnumCaseCodingKey = .auto, emptyPayloadOption: EnumCaseCodingEmptyPayloadOption) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: StaticString) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


@attached(peer)
public macro EnumCaseCoding<T>(unkeyedRawValuePayload: StaticString, type: T.Type) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")
where T: ExpressibleByStringLiteral, T: Codable, T: Equatable


@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: StaticBigInt) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro") 


@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: Int) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro") 


@attached(peer)
public macro EnumCaseCoding<T>(unkeyedRawValuePayload: T.IntegerLiteralType, type: T.Type) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro") 
where T: ExpressibleByIntegerLiteral, T: Codable, T: Equatable


@attached(peer)
public macro EnumCaseCoding(unkeyedRawValuePayload: Double) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro") 


@attached(peer)
public macro EnumCaseCoding<T>(unkeyedRawValuePayload: T.FloatLiteralType, type: T.Type) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")
where T: ExpressibleByFloatLiteral, T: Codable, T: Equatable


@attached(peer)
public macro EnumCaseCoding(unkeyedPayload: EnumCaseCodingPayload) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


@attached(peer)
public macro EnumCaseCoding(key: EnumCaseCodingKey = .auto, payload: EnumCaseCodingPayload) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")


@attached(peer)
public macro EnumCaseCoding(key: EnumCaseCodingKey) = #externalMacro(module: "CodableMacroMacros", type: "EnumCaseCodingMacro")