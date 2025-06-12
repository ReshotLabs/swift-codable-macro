//
//  CodingDefaultValue.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Default value configuration for ``SingleValueCodableProtocol``
///
/// Work exactly the same as the `Optional` type in Swift, used just to avoid nested Optional
public enum CodingDefaultValue<T> {
    /// No default value
    case none
    /// Has default value
    case value(T)
}


extension CodingDefaultValue: Sendable where T: Sendable {}
extension CodingDefaultValue: Equatable where T: Equatable {}
