//
//  CodingField.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



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
