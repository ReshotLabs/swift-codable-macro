//
//  CodingIgnore.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Mark a stored property to be ignored when doing encoding and decoding
///
/// - Attention: The stored property MUST be optional or have a initializer
@attached(peer)
public macro CodingIgnore() = #externalMacro(module: "CodableMacroMacros", type: "CodingIgnoreMacro")
