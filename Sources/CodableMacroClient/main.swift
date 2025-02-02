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
    @CodingField(default: 1)
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
    var field13Renamed: Int = 1
    
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
    
    
    init() {
        self.field1 = "field1"
        self.field2 = 1
        self.field3 = .init()
        self.field4 = 1
        self.field5 = 1
        self.field11 = 1
        self.field12 = 1
    }
    
}


let instance = TypeA()
let data = try JSONEncoder().encode(instance)

print(String(data: data, encoding: .utf8) ?? "")

let decodedInstance = try JSONDecoder().decode(TypeA.self, from: data)
print(decodedInstance == instance)


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


@Codable
struct TypeH: Equatable {
    @CodingField("a", "b", default: 2)
    var a: Int = 1
    @CodingIgnore
    var b: Int = 1
}


print(try JSONDecoder().decode(TypeH.self, from: .init(#"{"a": "1"}"#.utf8)) == TypeH(a: 2))
