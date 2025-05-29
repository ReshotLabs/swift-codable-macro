//
//  JsonComponent.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/11.
//

import Foundation


indirect enum JsonComponent: Codable, Hashable {
    case int(Int)
    case real(Double)
    case string(String)
    case bool(Bool)
    case null
    case array(Array<JsonComponent>)
    case object([String: JsonComponent])
}


extension JsonComponent {
    
    subscript(_ key: String) -> JsonComponent {
        switch self {
            case .object(let dictionary): dictionary[key] ?? .null
            default: .null
        }
    }
    
    subscript(_ index: Int) -> JsonComponent {
        switch self {
            case .array(let arr):
                guard index >= 0 && index < arr.count else {
                    return .null
                }
                return arr[index]
            default:
                return .null
        }
    }
    
    var intVal: Int? {
        switch self {
            case .int(let val): val
            default: nil
        }
    }
    
    var realVal: Double? {
        switch self {
            case .real(let val): val
            default: nil
        }
    }
    
    var stringVal: String? {
        switch self {
            case .string(let val): val
            default: nil
        }
    }
    
    var boolVal: Bool? {
        switch self {
            case .bool(let val): val
            default: nil
        }
    }
    
    var isNull: Bool {
        self == .null
    }
    
}


extension JsonComponent: CustomStringConvertible {
    
    var description: String {
        switch self {
            case .int(let int):
                int.description
            case .real(let double):
                double.description
            case .string(let string):
                #""\#(string)""#
            case .bool(let bool):
                bool.description
            case .null:
                "null"
            case .array(let set):
                set.description
            case .object(let dictionary):
                dictionary.description
        }
    }
    
}


extension JsonComponent:
    ExpressibleByDictionaryLiteral,
    ExpressibleByArrayLiteral,
    ExpressibleByNilLiteral,
    ExpressibleByBooleanLiteral,
    ExpressibleByStringLiteral,
    ExpressibleByFloatLiteral,
    ExpressibleByIntegerLiteral {
    
    init(dictionaryLiteral elements: (String, Self)...) {
        self = .object(.init(uniqueKeysWithValues: elements))
    }
    
    init(arrayLiteral elements: Self...) {
        self = .array(.init(elements))
    }
    
    init(nilLiteral: ()) {
        self = .null
    }
    
    init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
    
    init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
    
    init(floatLiteral value: FloatLiteralType) {
        self = .real(value)
    }
    
    init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
    
}


extension JsonComponent: Equatable {

    static func == (lhs: JsonComponent, rhs: JsonComponent) -> Bool {
        switch (lhs, rhs) {
            case (.int(let lhsVal), .int(let rhsVal)):
                return lhsVal == rhsVal
            case (.real(let lhsVal), .real(let rhsVal)):
                return lhsVal == rhsVal
            case (.string(let lhsVal), .string(let rhsVal)):
                return lhsVal == rhsVal
            case (.bool(let lhsVal), .bool(let rhsVal)):
                return lhsVal == rhsVal
            case (.null, .null):
                return true
            case (.array(let lhsArr), .array(let rhsArr)):
                return Set(lhsArr) == Set(rhsArr)
            case (.object(let lhsDict), .object(let rhsDict)):
                return lhsDict == rhsDict
            default:
                return false
        }
    }

}


extension JsonComponent {
    
    struct CodingKeys: CodingKey, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
        
        var stringValue: String
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init(intValue: Int) {
            self.intValue = intValue
            self.stringValue = intValue.description
        }
        
        init(integerLiteral value: IntegerLiteralType) {
            self.init(intValue: value)
        }
        
        init(stringLiteral value: StringLiteralType) {
            self.init(stringValue: value)
        }
        
    }
    
    
}


extension JsonComponent {
    
    func encode(to encoder: any Encoder) throws {
        
        switch self {
            case .object(let dict):
                var nestedContainer = encoder.container(keyedBy: CodingKeys.self)
                for (innerKey, value) in dict {
                    try encode(value, key: .init(stringValue: innerKey), to: &nestedContainer)
                }
            case .array(let array):
                var nestedContainer = encoder.unkeyedContainer()
                for value in array {
                    try encode(value, to: &nestedContainer)
                }
            case .int(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .string(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .null:
                var container = encoder.singleValueContainer()
                try container.encodeNil()
            case .real(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .bool(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
        }
        
    }
    
    
    private func encode(_ json: JsonComponent, key: CodingKeys, to container: inout KeyedEncodingContainer<CodingKeys>) throws {
        
        switch json {
            case .object(let dict):
                var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: key)
                for (innerKey, value) in dict {
                    try encode(value, key: .init(stringValue: innerKey), to: &nestedContainer)
                }
            case .array(let array):
                var nestedContainer = container.nestedUnkeyedContainer(forKey: key)
                for value in array {
                    try encode(value, to: &nestedContainer)
                }
            case .bool(let boolVal):
                try container.encode(boolVal, forKey: key)
            case .int(let intVal):
                try container.encode(intVal, forKey: key)
            case .real(let realVal):
                try container.encode(realVal, forKey: key)
            case .string(let stringVal):
                try container.encode(stringVal, forKey: key)
            case .null:
                try container.encodeNil(forKey: key)
        }
        
    }
    
    
    private func encode(_ json: JsonComponent, to container: inout UnkeyedEncodingContainer) throws {
        
        switch json {
                
            case .object(let dict):
                var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self)
                for (innerKey, value) in dict {
                    try encode(value, key: .init(stringValue: innerKey), to: &nestedContainer)
                }
            case .array(let array):
                var nestedContainer = container.nestedUnkeyedContainer()
                for value in array {
                    try encode(value, to: &nestedContainer)
                }
            case .bool(let boolVal):
                try container.encode(boolVal)
            case .int(let intVal):
                try container.encode(intVal)
            case .real(let realVal):
                try container.encode(realVal)
            case .string(let stringVal):
                try container.encode(stringVal)
            case .null:
                try container.encodeNil()
                
        }
        
    }
    
}


extension JsonComponent {
    
    init(from decoder: any Decoder) throws {
        
        func decode(from container: KeyedDecodingContainer<CodingKeys>) throws -> JsonComponent {
            
            var json = [String: JsonComponent]()
            
            for key in container.allKeys {
                
                if let intVal = try? container.decode(Int.self, forKey: key) {
                    json[key.stringValue] = .int(intVal)
                } else if let realVal = try? container.decode(Double.self, forKey: key) {
                    json[key.stringValue] = .real(realVal)
                } else if let boolVal = try? container.decode(Bool.self, forKey: key) {
                    json[key.stringValue] = .bool(boolVal)
                } else if (try? container.decodeNil(forKey: key)) == true {
                    json[key.stringValue] = .null
                } else if let nestedContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: key) {
                    json[key.stringValue] = try decode(from: nestedContainer)
                } else if var nestedContainer = try? container.nestedUnkeyedContainer(forKey: key) {
                    json[key.stringValue] = try decode(from: &nestedContainer)
                } else if let stringVal = try? container.decode(String.self, forKey: key) {
                    json[key.stringValue] = .string(stringVal)
                }
                
            }
            
            return .object(json)
            
        }
        
        
        func decode(from container: inout UnkeyedDecodingContainer) throws -> JsonComponent {
            
            var json = Array<JsonComponent>()
            
            for _ in 0 ..< (container.count ?? 0) {
                
                if let intVal = try? container.decode(Int.self) {
                    json.append(.int(intVal))
                } else if let realVal = try? container.decode(Double.self) {
                    json.append(.real(realVal))
                } else if let boolVal = try? container.decode(Bool.self) {
                    json.append(.bool(boolVal))
                } else if (try? container.decodeNil()) == true {
                    json.append(.null)
                } else if let nestedContainer = try? container.nestedContainer(keyedBy: CodingKeys.self) {
                    json.append(try decode(from: nestedContainer))
                } else if var nestedContainer = try? container.nestedUnkeyedContainer() {
                    json.append(try decode(from: &nestedContainer))
                } else if let stringVal = try? container.decode(String.self) {
                    json.append(.string(stringVal))
                }
                
            }
            
            return .array(json)
            
        }
        
        
        func decode(from container: inout SingleValueDecodingContainer) throws -> JsonComponent {
            return if let intVal = try? container.decode(Int.self) {
                .int(intVal)
            } else if let realVal = try? container.decode(Double.self) {
                .real(realVal)
            } else if let boolVal = try? container.decode(Bool.self) {
                .bool(boolVal)
            } else if container.decodeNil() == true {
                .null
            } else if let stringVal = try? container.decode(String.self) {
                .string(stringVal)
            } else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self = try decode(from: container)
        } else if var container = try? decoder.unkeyedContainer() {
            self = try decode(from: &container)
        } else if var container = try? decoder.singleValueContainer() {
            self = try decode(from: &container)
        } else {
            throw CocoaError(.coderInvalidValue)
        }
        
    }
    
}

