//
//  Type.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/1.
//


/// Return the type of the input expression,
/// where the expression will not be evaluated (due to the use of autoclosure
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



public protocol SingleValueCodableProtocol: Codable {
    
    associatedtype CodingValue: Codable
    
    func singleValueEncode() throws -> CodingValue
    
    init(from codingValue: CodingValue) throws
    
}



extension SingleValueCodableProtocol {
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(CodingValue.self)
        try self.init(from: value)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let codingValue = try self.singleValueEncode()
        try container.encode(codingValue)
    }
    
}
