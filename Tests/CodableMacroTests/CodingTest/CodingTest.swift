//
//  CodingTest.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/23.
//

import Testing
import Foundation


@Suite("Test Actual Coding")
class CodingTest {
    
    func codingTestDecodeAssert<T: Decodable & Sendable & Equatable>(
        _ expectedInstance: DecodeResult<T>,
        _ json: JsonComponent
    ) throws {
        let encoded = try JSONEncoder().encode(json)
        
        switch expectedInstance {
            case .success(let result):
                let decoded = try JSONDecoder().decode(T.self, from: encoded)
                #expect(result == decoded)
            case .error:
                #expect(throws: Error.self) {
                    _ = try JSONDecoder().decode(T.self, from: encoded)
                }
        }
    }
    
    
    
    func codingTestEncodeAssert<T: Encodable>(
        _ instance: T,
        _ expectedJson: JsonComponent
    ) throws {
        let encoded = try JSONEncoder().encode(instance)
        let decodedAsJsonComponent = try JSONDecoder().decode(JsonComponent.self, from: encoded)
        #expect(decodedAsJsonComponent == expectedJson)
    }
    
    
    enum DecodeResult<T: Decodable & Sendable>: Sendable {
        case success(T)
        case error
        func get() throws -> T {
            switch self {
                case .success(let result): result
                case .error: throw CocoaError(.coderReadCorrupt)
            }
        }
        var isError: Bool {
            switch self {
                case .success: false
                case .error: true
            }
        }
    }
    
}
