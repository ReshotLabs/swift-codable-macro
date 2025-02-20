//
//  Type.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/1.
//


/// Return the type of the input expression,
/// where the expression will not be evaluated (due to the use of autoclosure)
///
/// ```swift
/// func test() -> Int {
///     print("executed")
///     return 1
/// }
///
/// print(codableMacroStaticType(of: test()))
/// // > Int
/// // the `executed` will not be printed
/// ```
public func codableMacroStaticType<T>(of _: @autoclosure () throws -> T) -> T.Type {
    return T.self
}



/// Protocol of types that delegate the decoding / encoding process to instances of another type
///
/// It has provided the implementation of [`encode(to:)`] and [`init(from:)`].
/// Require to implement:
/// * ``singleValueEncode()`` to convert the instance to an instance of another type
/// for being encoded
/// * ``init(from:)`` to create an instance of this type using an instance of another type
/// being decoded
///
/// [`encode(to:)`]: https://developer.apple.com/documentation/swift/encodable/encode(to:)-7ibwv
/// [`init(from:)`]: https://developer.apple.com/documentation/swift/decodable/init(from:)-8ezpn
public protocol SingleValueCodableProtocol: Codable {
    
    /// The type for actual encoding / decoding process
    associatedtype CodingValue: Codable
    
    /// Convert the instance to an instance of another type for being encoded
    func singleValueEncode() throws -> CodingValue
    
    /// Create an instance of this type using an instance of another type being decoded
    init(from codingValue: CodingValue) throws
    
}



extension SingleValueCodableProtocol {
    
    public init(from decoder: any Decoder) throws {
        try self.init(from: .init(from: decoder))
    }
    
    public func encode(to encoder: any Encoder) throws {
        try self.singleValueEncode().encode(to: encoder)
    }
    
}
