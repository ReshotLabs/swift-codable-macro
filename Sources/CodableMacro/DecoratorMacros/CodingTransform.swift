//
//  CodingTransform.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



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
public macro CodingTransform(
    _ transformers: any EvenCodingTransformProtocol...
) = #externalMacro(module: "CodableMacroMacros", type: "CodingTransformMacro")
