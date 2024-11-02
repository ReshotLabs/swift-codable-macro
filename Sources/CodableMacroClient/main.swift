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
    
    @CodingField("field12")
    var field12Renamed: Int = 1
    
    var field12: Int {
        get { field12Renamed }
        set { field12Renamed = newValue }
    }
    
    // conflict path (exact) (uncomment to check the error message)
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
    var b = 1
}
