// The Swift Programming Language
// https://docs.swift.org/swift-book



@attached(extension, conformances: Codable, names: arbitrary)
public macro Codable() = #externalMacro(module: "CodableMacroMacros", type: "CodableMacro")



@attached(peer)
public macro CodingField<T>(_ path: String..., default: T) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")


@attached(peer)
public macro CodingField(_ path: String...) = #externalMacro(module: "CodableMacroMacros", type: "CodingFieldMacro")



@attached(peer)
public macro CodingIgnore() = #externalMacro(module: "CodableMacroMacros", type: "CodingIgnoreMacro")
