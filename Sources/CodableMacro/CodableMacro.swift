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



@attached(peer)
public macro DecodeTransform<Source: Decodable, Target>(
    source sourceType: Source.Type,
    target targetType: Target.Type = Target.self,
    with transform: @escaping (Source) throws -> Target
) = #externalMacro(module: "CodableMacroMacros", type: "DecodeTransformMacro")


@attached(peer)
public macro EncodeTransform<Source, Target: Encodable>(
    source sourceType: Source.Type = Source.self,
    target targetType: Target.Type = Target.self,
    with transform: @escaping (Source) throws -> Target
) = #externalMacro(module: "CodableMacroMacros", type: "EncodeTransformMacro")
