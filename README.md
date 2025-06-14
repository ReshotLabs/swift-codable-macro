# swift-codable-macro

Provide Swift Macros for automatically generate customizable implementation for conforming `Codable` protocol. 

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStar-Lord-PHB%2Fswift-codable-macro%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Star-Lord-PHB/swift-codable-macro) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStar-Lord-PHB%2Fswift-codable-macro%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Star-Lord-PHB/swift-codable-macro)

## Introduction 

Swift Compiler already provides auto implementation when we conform a custom type to `Codable`. It is nice when you are in charge of defining the encoding / decoding format, but unfortunately, that is not always the case. When the format is defined by others, we might have to use wired property name or even implement `encode(to:)` and `init(:from)` ourselves. 

Such problem usually occurs when using an REST API provided by some third parties. For example, we might expect a `Person` struct to be something like this: 

```swift
public struct Person: Codable {
    var id: String
    var name: String 
    var age: Int
}
```

However, the response body of the REST API might, for some reason, be something like this: 

```json
{
    "data": {
        "id": "9F6E1D7A-EF6A-4F7A-A1E0-46105DD31F3E",
        "meta": {
            "name": "Serika",
            "age": 15
        }
    }
}
```

In this case, we have to implement the conformance to `Codable` ourselves. 

To handle such situation in a "swifter" way, the `swift-codable-macro` is here to help. For the example above, we can how declare the `Person` Struct like this: 

```swift
@Codable
public struct Person {
    @CodingField("data", "id")
    var id: String
    @CodingField("data", "meta", "name")
    var name: String 
    @CodingField("data", "meta", "age")
    var age: Int
}
```

Done! The `Codable` conformance and implementation of `encode(to:)` and `init(from:)` will be generated automatically! No other additional implementation code required! 

This is not all the capability of this package. The following codes provide a brief view of what it can do. 

```swift
@Codable
struct Person {
    
    @CodingField("data", "uid")
    @DecodeTransform(source: String.self, with: { UUID(uuidString: $0)! })
    @EncodeTransform(source: UUID.self, with: \.uuidString)
    var id: UUID
    
    @CodingField("data", "meta", "name")
    @CodingValidate(source: String.self, with: { !$0.isEmpty })
    @CodingValidate(source: String.self, with: { !$0.contains(where: { $0.isNumber }) })
    var name: String 
    
    @CodingField("data", "meta", "gender", onMissing: .male, onMismatch: .female)
    let gender: Gender
    
    @CodingField("data", "meta", "birth", default: Date.distancePast)
    @CodingTransform(
        .date.timeIntervalTransform(), 
        .double.multiRepresentationTransform(encodeTo: .string)
    )
    var birthday: Date
    
    @CodingField("data", "meta", "known_programming_languages")
    @SequenceCodingField(
        subPath: "name", 
        onMissing: .ignore, 
        onMismatch: .value("Swift"),
        decodeTransform: Set.init
    )
    var knownProgrammingLanguages: Set<String>
    
    @CodingIgnore
	var habit: String = "writing Swift Macro"
    
}
```

```swift
@SingleValueCodable
struct FilePath {
    @SingleValueCodableDelegate
    var storage: String
    var isDir: Bool = false 
}
```

```swift
@EnumCodable(option: .adjacentKeyed())
enum Example {
    @EnumCaseCoding(caseKey: "a_key", emptyPayloadOption: .emptyObject)
    case a
    @EnumCaseCoding(caseKey: "a_key", payload: .singleValue)
    case b(Int)
    @EnumCaseCoding(payload: .object(keys: "key1", "key2", "key3"))
    case c(Int, label: String, _: Int)
}
```

## Provided Macros

For more detailed guidance, see [documentation](https://swiftpackageindex.com/Star-Lord-PHB/swift-codable-macro/documentation/codablemacro) 

### Keyed Coding

| Macro                                  | Description                                                  |
| -------------------------------------- | ------------------------------------------------------------ |
| `Codable(inherit:)`                    | Annotate a class or a struct for auto conforming to `Codable` |
| `CodingField(_:default:)`              | Provide custom coding path and default value for a property  |
| `CodingField(_:onMissing:onMismatch:)` | Provide custom coding path and default value in different error cases for a property |
| `CodingIgnore`                         | Ignore a property                                            |
| `DecodeTransform(source:with:)`        | Specify a transformation when decoding                       |
| `EncodeTransform(source:with:)`        | Specify a transformation when encoding                       |
| `CodingTransform(_:)`                  | Specify Coding Transformations for both Encoding and Decoding |
| `CodingValidate(source:with:)`         | Validation performed when the value for the property is decoded |
| `SequenceCodingField`                  | Provide settings for properties that are `Sequence`          |

### Single Value Coding 

| Macro                          | Description                                                  |
| ------------------------------ | ------------------------------------------------------------ |
| `SingleValueCodable(inherit:)` | Annotate a class or a struct for auto conforming to `Codable` by encoding the instance into a single value |
| `SingleValueCodableDelegate`   | Mark a member property as the required "single value" for encoding and decoding |

### Enum Coding

| Macro                                        | Description                                                  |
| -------------------------------------------- | ------------------------------------------------------------ |
| `EnumCodable(option:)`                       | Annotate an enum for auto conforming to `Codable`            |
| `EnumCaseCoding(caseKey:payload)`            | Provide settings of case key and payload for an enum case with associated values |
| `EnumCaseCoding(caseKey:emptyPayloadOption)` | Provide settings of case key and emptyPayload representation for an enum case without associated values |
| `EnumCaseCoding(unkeyedRawValuePayload:)`    | Provide a rawValue as the payload for an enum case without associated values |
| `EnumCaseCoding(unkeyedPayload:)`            | Provide settings of payload for an enum case with associated values |

_The design of the APIs for Enum Coding is inspired by the [Serde](https://serde.rs) framework from Rust_

## Installation 

In `Package.swift`, add the following line into your dependencies: 

```swift
.package(url: "https://github.com/Star-Lord-PHB/swift-codable-macro.git", from: "3.0.0")
```

Add `CodableMacro` as a dependency of your target:

```swift
.target(
    name: "Target", 
    dependencies: [
        .product(name: "CodableMacro", package: "swift-codable-macro"),
    ]
)
```

Add `import CodableMacro` in your source code. 