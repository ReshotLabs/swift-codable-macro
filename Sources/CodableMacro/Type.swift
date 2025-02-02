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
