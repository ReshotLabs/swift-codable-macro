//
//  SequenceCodingFieldErrorStrategy.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/6/12.
//



/// Behaviour for elements that cannot be decoded correctly in an encoded sequence (e.g.: JSON Array)
public enum SequenceCodingFieldErrorStrategy<T> {
    /// Throw [`DecodingError`]
    ///
    /// [`DecodingError`]: https://developer.apple.com/documentation/swift/decodingerror
    case throwError
    /// Skip this element and continue
    case ignore
    /// Apply and default value and continue
    case value(T)
}



extension SequenceCodingFieldErrorStrategy: Sendable where T: Sendable {}
extension SequenceCodingFieldErrorStrategy: Equatable where T: Equatable {}
