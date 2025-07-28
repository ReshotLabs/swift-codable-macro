//
//  KeyedCodableMacros.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Key decoding strategies that can be applied to automatically transform property names
public enum KeyDecodingStrategy {
    /// Use the keys specified by the property names as written in Swift
    case useDefaultKeys
    /// Convert camelCase Swift property names to snake_case keys
    case convertFromSnakeCase
    /// Use a custom function to transform keys
    case custom((String) -> String)
}

/// Automatically make the marked `class` or `struct` to conform to [`Codable`]
/// - Parameter inherit: Whether this class has an super class that has already conformed to [`Codable`]
/// - Parameter keyDecodingStrategy: Strategy for transforming Swift property names to coding keys
///
/// When being expanded, it will look up all the stored properties and automatically generate
/// the implementation of [`encode(to:)`] and [`init(from:)`]
///
/// * As long as a property is not marked as ``CodingIgnore()``, it will be considered in the
/// implementation
/// * Optional and default value will be considered when decoding
///
/// You can specify a custom coding path and a default value using ``CodingField(_:)``
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
/// An example usage is as follow:
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
/// To support APIs that use snake_case, use:
///
/// ```swift
/// @Codable(keyDecodingStrategy: .convertFromSnakeCase)
/// struct GameConfig {
///     @CodingField(onMissing: true)
///     var hidePartyGames: Bool  // Will map to "hide_party_games" in JSON
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
public macro Codable(inherit: Bool = false, keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys) = #externalMacro(module: "CodableMacroMacros", type: "CodableMacro")
