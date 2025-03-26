import Foundation
import CodableMacro


@Codable
struct TypeA: Equatable {
    
    // default
    @CodingField
    var field1: String
    
    // custom path
    @CodingField("meta", "field2")
    let field2: Int
    
    // standard
    private let field3: Date

    // macro specified default value
    @CodingField("meta", "field4", default: 1)
    let field4: Int
    
    // macro specified default value suppress the default initializer
    @CodingField(default: 1)
    var field5: Int = 2
    
    // with default initializer
    @CodingField("path1", "path2", "field6")
    var field6: Int = 1
    
    // optional
    @CodingField
    var field7: Int?
    
    // optional with default value
    @CodingField(default: 1)
    var field8: Int? = 2
    
    // not initializable constant (should be ignored when decoding)
    @CodingField
    let field9: Int = 2
    
    // stored property with observer
    @CodingField
    var field10: Int = 0 {
        willSet { print(newValue) }
    }
    
    // default value with optional path
    @CodingField("optional_path", "field11", default: 1)
    var field11: Int
    
    @CodingField("optional_path", "optional_path2", "field12", default: 1)
    var field12: Int
    
    @CodingField("field13")
    @DecodeTransform(source: String.self, with: { Int($0)! })
    @EncodeTransform(source: Int.self, with: \.description)
    @CodingValidate(source: Int.self, with: { $0 % 2 == 0 })
    @CodingValidate(source: Int.self, with: { $0 > 0 })
    var field13Renamed: Int = 2
    
    var field13: Int {
        get { field13Renamed }
        set { field13Renamed = newValue }
    }
    
//     conflict path (exact) (uncomment to check the error message)
//    @CodingField("meta", "field2")
//    var fieldError1: Int = 1
    
    // conflict path (prefix) (uncomment to check the error message)
//    @CodingField("meta")
//    var fieldError2: Int = 1
    
    // computed property (uncomment to check the error message)
//    @CodingField
//    var fieldError3: Int { 1 }
    
    @CodingIgnore
    var fieldIgnored1: Bool = false
    
    
    var ignoredComputed: Int { 1 }
    
    
    init(field13: Int = 2) {
        self.field1 = "field1"
        self.field2 = 1
        self.field3 = .init()
        self.field4 = 1
        self.field5 = 1
        self.field11 = 1
        self.field12 = 1
        self.field13Renamed = field13
    }
    
}


let instance = TypeA()
let data = try JSONEncoder().encode(instance)

print(String(data: data, encoding: .utf8) ?? "")

let decodedInstance = try JSONDecoder().decode(TypeA.self, from: data)
print(decodedInstance == instance)


do {
    _ = try JSONDecoder().decode(
        TypeA.self,
        from: JSONEncoder().encode(TypeA(field13: 1))
    )
} catch {
    print(error)
}

do {
    _ = try JSONDecoder().decode(
        TypeA.self,
        from: JSONEncoder().encode(TypeA(field13: -2))
    )
} catch {
    print(error)
}


// contains a coding ignore, still have to provide implementation instead of using that
// provided by the Swift Compiler
@Codable
struct Test {
    var a = 1
    @CodingIgnore
    var b: Int?
}




@Codable
class TypeB {
    
    @CodingField("field")
    var a: Int = 0
    var b: Int = 0
    
}

extension TypeB: Equatable {
    static func == (lhs: TypeB, rhs: TypeB) -> Bool {
        lhs.a == rhs.a &&
        lhs.b == rhs.b
    }
}


@Codable
class TypeC {
    @CodingField("field")
    var a: Int = 0
    init(a: Int) {
        self.a = a
    }
}



@Codable
final class TypeD {
    @CodingField("1", "2", "a", default: 0)
    var a: Int = 0
    @CodingField("1", "2", "b", default: 0)
    var b: Int = 0
    @CodingField("1", "c", default: 0)
    var c: Int = 0
    var d: Int = 0
}



@Codable
class TypeE {
    var a: Int
}


@Codable
struct TypeF {
    @CodingField("test", "test", "test")
    let a: String?
}


//@Codable
//class TypeG {
////    var a: Int
//}


func advanceByOne(input: Int) -> UInt {
    UInt(input + 1)
}


struct IntStrCodingTransformer: EvenCodingTransformProtocol {
    func decodeTransform(_ value: String) throws -> Int {
        .init(value)!
    }
    func encodeTransform(_ value: Int) throws -> String {
        value.description
    }
}


struct IdenticalTransformer<T: Codable>: EvenCodingTransformProtocol {
    func decodeTransform(_ value: T) throws -> T { value }
    func encodeTransform(_ value: T) throws -> T { value }
}


@Codable
struct TypeH: Equatable {
    @DecodeTransform(source: Int.self, with: advanceByOne(input:))
    @EncodeTransform(source: UInt.self, with: { Int($0 - 1) })
    @CodingField("a", "b", default: 2)
    var a: UInt = 1
    @CodingIgnore
    var b: Int = 1
    // CodingTransform and DecodeTransform cannot be used together (uncomment to check the error message)
//    @DecodeTransform(source: String.self, with: { Int($0)! })
    @CodingTransform(IntStrCodingTransformer())
    var c: Int = 1
    @CodingTransform(.iso8601DateTransform, IdenticalTransformer<String>())
    var d: Date = .distantPast
    @CodingTransform(.boolTransform(option: .customString(true: "t", false: "f")))
    var e: Bool = false
    @CodingTransform(.dataBase64Transform(options: .lineLength76Characters))
    var f: Data = .init()
}


print(String(data: try JSONEncoder().encode(TypeH(c: 4)), encoding: .utf8)!)
print(
    try JSONDecoder().decode(TypeH.self, from: .init(#"{"a": "1", "c": "2", "d": "2021-01-01T00:00:00Z", "e": "t"}"#.utf8))
    == TypeH(a: 2, c: 2, d: Calendar.current.date(from: .init(timeZone: .init(secondsFromGMT: 0), year: 2021, month: 1, day: 1))!, e: true)
)
print(try JSONDecoder().decode(TypeH.self, from: .init(#"{"a": {"b": 3}, "c": "4", "e": "f"}"#.utf8)) == TypeH(a: 4, c: 4))



@SingleValueCodable
struct TypeI {
    var a: Int
    func singleValueEncode() throws -> String {
        return a.description
    }
    init(from codingValue: String) throws {
        guard let value = Int(codingValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        }
        self.a = value
    }
}



@SingleValueCodable
class TypeJ {
    @SingleValueCodableDelegate
    var a: TypeB?
    var b: Int = 1
    // property that require initialization (uncomment to check the error message)
//    var c: Int
    init(a: TypeB? = nil, b: Int = 1) {
        self.a = a
        self.b = b
    }
}

extension TypeJ: Equatable {
    static func == (lhs: TypeJ, rhs: TypeJ) -> Bool {
        lhs.a == rhs.a &&
        lhs.b == rhs.b
    }
}


let typeJInstance = TypeJ(a: .init())
typeJInstance.a?.a = 2
typeJInstance.a?.b = 5
print(String(data: try JSONEncoder().encode(typeJInstance), encoding: .utf8)!)
print(try JSONDecoder().decode(TypeJ.self, from: .init(#"{"field": 2, "b": 5}"#.utf8)) == typeJInstance)



@SingleValueCodable
struct TypeK {
    @SingleValueCodableDelegate
    let a: String = ""
    // computed property not allowed (uncomment to check the error message)
//    @SingleValueCodableDelegate
//    var b: Int? { .init(a) }
    // multiple delegate (uncomment to check the error message)
//    @SingleValueCodableDelegate
//    var c: Int = 1
}



class TestClass: Codable {
    var a: Int
    init(a: Int) {
        self.a = a
    }
}


final class TestSubClass: TestClass {
    var b: Int
    init(b: Int) {
        self.b = b
        super.init(a: 1)
    }
    required init(from decoder: any Decoder) throws {
        self.b = 1
        super.init(a: 1)
    }
    override func encode(to encoder: any Encoder) throws {
        
    }
}
