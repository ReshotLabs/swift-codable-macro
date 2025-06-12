//
//  SingleValueCodableDelegate.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



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
