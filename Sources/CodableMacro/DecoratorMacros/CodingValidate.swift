//
//  CodingValidate.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



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
