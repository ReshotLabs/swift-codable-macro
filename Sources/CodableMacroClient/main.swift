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
    
    // conflict path (exact) (uncomment to check the error message)
//    @CodingField("meta", "field2")
//    var fieldError1: Int = 1
    
    // conflict path (prefix) (uncomment to check the error message)
//    @CodingField("meta")
//    var fieldError2: Int = 1
    
    // computed property
//    @CodingField
//    var fieldError3: Int { 1 }
    
    @CodingIgnore
    var fieldIgnored1: Bool = false
    
    
    init() {
        self.field1 = "field1"
        self.field2 = 1
        self.field3 = .init()
        self.field4 = 1
        self.field5 = 1
    }
    
}


let instance = TypeA()
let data = try JSONEncoder().encode(instance)

print(String(data: data, encoding: .utf8) ?? "")

let decodedInstance = try JSONDecoder().decode(TypeA.self, from: data)
print(decodedInstance == instance)




@Codable
struct TypeB {
    var field1: Int
    var field2: Int?
    var field3: Int = 1
    @CodingField("path1", "path2", "field4")
    var field4: Int
    @CodingField("path1", "field5")
    var field5: Int = 1
    @CodingField("path1", "path2", "field6", default: 2)
    var field6: Int = 1
    @CodingField("path1", "path2", "field7")
    var field7: Int?
    @CodingField("path2", "field8")
    let field8: Int = 1
    @CodingIgnore
    var fieldIgnore1: Int?
    @CodingIgnore
    var fieldIgnore2: Int = 1
}
