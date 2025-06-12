//
//  SingleValueCodableMacros.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



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
