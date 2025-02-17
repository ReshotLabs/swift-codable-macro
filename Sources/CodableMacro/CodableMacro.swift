// The Swift Programming Language
// https://docs.swift.org/swift-book



/// Automatically make the marked `class` or `struct` to conform to [`Codable`]
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
public macro Codable() = #externalMacro(module: "CodableMacroMacros", type: "CodableMacro")



/// Provide customization for a stored property when doing encoding and decoding
/// - Parameter path: The coding path for fetching / storing the value in the encoded data
/// - Parameter default: The default value to use when the value does not exist in the encoded data
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
/// - Attention: Must be used together with ``Codable()``
@attached(peer)
public macro CodingField(_ path: String...) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")



/// Mark a stored property to be ignored when doing encoding and decoding
///
/// - Attention: The stored property MUST be optional or have a initializer
@attached(peer)
public macro CodingIgnore() = #externalMacro(module: "CodableMacroMacros", type: "CodingIgnoreMacro")



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


/// Automatically make the annotated `class` or `struct` to conform to [`Codable`] by converting
/// instances from/to instances of another type.
///
/// What this macro does is simply conform the type to ``SingleValueCodableProtocol``, which
/// has already provided the implementation of [`encode(to:)`] and [`init(from:)`], but requires
/// implementation of:
/// * ``SingleValueCodableProtocol/singleValueEncode()``: Convert the instance to an
/// instance of another type that will actually be encoded.
/// * ``SingleValueCodableProtocol/init(from:)``: Create an instance of this type using an
/// instance of another type being decoded.
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
@attached(extension, conformances: SingleValueCodableProtocol, names: arbitrary)
public macro SingleValueCodable() = #externalMacro(module: "CodableMacroMacros", type: "SingleValueCodableMacro")


/// Annotate a stored property as the only property responsible for the encoding and decoding
/// process.
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
///
/// - Attention: This macro can ONLY be applied to stored properties and will raise compilation
/// error if applied to the wrong target
/// ```
@attached(peer)
public macro SingleValueCodableDelegate() = #externalMacro(module: "CodableMacroMacros", type: "SingleValueCodableDelegateMacro")
