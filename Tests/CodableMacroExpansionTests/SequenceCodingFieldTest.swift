import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport

@testable import CodableMacro

#if canImport(CodableMacroMacros)
@testable import CodableMacroMacros
#endif


extension CodingExpansionTest {

    @Suite("Test SequenceCodingField macro")
    class SequenceCodingFieldTest: CodingExpansionTest {}

}



extension CodingExpansionTest.SequenceCodingFieldTest {

    @Codable
    struct Test1 {
        @CodingField("path", "outer")
        @SequenceCodingField(subPath: "inner", "a", elementEncodedType: Int.self)
        var a: [Int]
        @CodingField("path", "outer")
        @SequenceCodingField(subPath: "inner", "b", elementEncodedType: Int.self)
        var b: [Int]
    }

    @Test
    func test1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path", "outer")
                @SequenceCodingField(subPath: "inner", "a", elementEncodedType: Int.self)
                var a: [Int]
                @CodingField("path", "outer")
                @SequenceCodingField(subPath: "inner", "b", elementEncodedType: Int.self)
                var b: [Int]
            }
            """, 
            expandedSource: #"""
            struct Test {
                var a: [Int]
                var b: [Int]
            }

            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath = "path"
                }
                enum $__coding_container_keys_root_path: String, CodingKey {
                    case kouter = "outer"
                }
                enum $__coding_container_keys_root_path_outer_root: String, CodingKey {
                    case kinner = "inner"
                }
                enum $__coding_container_keys_root_path_outer_root_inner: String, CodingKey {
                    case ka = "a", kb = "b"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    let $__coding_container_root_path = try $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path.self,
                        forKey: .kpath
                    )
                    do {
                        var $__coding_container_root_path_outer = try $__coding_container_root_path.nestedUnkeyedContainer(
                            forKey: .kouter
                        )
                        var $__sequence_coding_temp_a = $__coding_make_empty_array(ofType: Int.self)
                        var $__sequence_coding_temp_b = $__coding_make_empty_array(ofType: Int.self)
                        while !$__coding_container_root_path_outer.isAtEnd {
                            let $__coding_container_root_path_outer_root = try $__coding_container_root_path_outer.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_outer_root.self
                            )
                            let $__coding_container_root_path_outer_root_inner = try $__coding_container_root_path_outer_root.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_outer_root_inner.self,
                                forKey: .kinner
                            )
                            do {
                                let rawValue = try $__coding_container_root_path_outer_root_inner.decode(
                                    Int.self,
                                    forKey: .ka
                                )
                                $__sequence_coding_temp_a.append(rawValue)
                            }
                            do {
                                let rawValue = try $__coding_container_root_path_outer_root_inner.decode(
                                    Int.self,
                                    forKey: .kb
                                )
                                $__sequence_coding_temp_b.append(rawValue)
                            }
                        }
                        do {
                            let rawValue = $__sequence_coding_temp_a
                            let value = rawValue
                            self.a = value
                        }
                        do {
                            let rawValue = $__sequence_coding_temp_b
                            let value = rawValue
                            self.b = value
                        }
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    var $__coding_container_root_path = $__coding_container_root.nestedContainer(
                        keyedBy: $__coding_container_keys_root_path.self,
                        forKey: .kpath
                    )
                    do {
                        var $__coding_container_root_path_outer = $__coding_container_root_path.nestedUnkeyedContainer(
                            forKey: .kouter
                        )
                        let $__sequence_coding_temp_a = try { () throws in
                            let transformedValue = self.a
                            return transformedValue
                        }()
                        for $__sequence_coding_element_a in $__sequence_coding_temp_a {
                            var $__coding_container_root_path_outer_root = $__coding_container_root_path_outer.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_outer_root.self
                            )
                            var $__coding_container_root_path_outer_root_inner = $__coding_container_root_path_outer_root.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_outer_root_inner.self,
                                forKey: .kinner
                            )
                            try $__coding_container_root_path_outer_root_inner.encode(
                                $__sequence_coding_element_a,
                                forKey: .ka
                            )
                        }
                    }
                    do {
                        var $__coding_container_root_path_outer = $__coding_container_root_path.nestedUnkeyedContainer(
                            forKey: .kouter
                        )
                        let $__sequence_coding_temp_b = try { () throws in
                            let transformedValue = self.b
                            return transformedValue
                        }()
                        for $__sequence_coding_element_b in $__sequence_coding_temp_b {
                            var $__coding_container_root_path_outer_root = $__coding_container_root_path_outer.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_outer_root.self
                            )
                            var $__coding_container_root_path_outer_root_inner = $__coding_container_root_path_outer_root.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_outer_root_inner.self,
                                forKey: .kinner
                            )
                            try $__coding_container_root_path_outer_root_inner.encode(
                                $__sequence_coding_element_b,
                                forKey: .kb
                            )
                        }
                    }
                }
            }
            """#
        )
    }


    @Codable
    struct Test2 {
        @CodingField("path")
        @SequenceCodingField(
            elementEncodedType: Int.self, 
            decodeTransform: Set.init, 
            encodeTransform: Array.init
        )
        var a: Set<Int>
    }

    @Test
    func test2() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path")
                @SequenceCodingField(
                    elementEncodedType: Int.self, 
                    decodeTransform: Set.init, 
                    encodeTransform: Array.init
                )
                var a: Set<Int>
            }
            """, 
            expandedSource: #"""
            struct Test {
                var a: Set<Int>
            }

            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath = "path"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        var $__coding_container_root_path = try $__coding_container_root.nestedUnkeyedContainer(
                            forKey: .kpath
                        )
                        var $__sequence_coding_temp_a = $__coding_make_empty_array(ofType: Int.self)
                        while !$__coding_container_root_path.isAtEnd {
                            do {
                                let rawValue = try $__coding_container_root_path.decode(Int.self)
                                $__sequence_coding_temp_a.append(rawValue)
                            }
                        }
                        do {
                            let rawValue = try $__coding_transform($__sequence_coding_temp_a, Set.init)
                            let value = rawValue
                            self.a = value
                        }
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        var $__coding_container_root_path = $__coding_container_root.nestedUnkeyedContainer(
                            forKey: .kpath
                        )
                        let $__sequence_coding_temp_a = try { () throws in
                            let transformedValue = self.a
                            return try $__coding_transform(transformedValue, Array.init)
                        }()
                        for $__sequence_coding_element_a in $__sequence_coding_temp_a {
                            try $__coding_container_root_path.encode($__sequence_coding_element_a)
                        }
                    }
                }
            }
            """#
        )
    }


    @Codable
    struct Test3 {
        @CodingField("path", onMissing: [1:1], onMismatch: [2:2])
        @SequenceCodingField(
            subPath: "inner", "a", 
            elementEncodedType: Int.self, 
            onMissing: .value(-1),
            onMismatch: .ignore,
            decodeTransform: { Dictionary(zip($0, $0), uniquingKeysWith: { $1 }) }, 
            encodeTransform: { $0.values }
        )
        var a: [Int:Int]
    }

    @Test
    func test3() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path", onMissing: [1:1], onMismatch: [2:2])
                @SequenceCodingField(
                    subPath: "inner", "a", 
                    elementEncodedType: Int.self, 
                    onMissing: .value(-1),
                    onMismatch: .ignore,
                    decodeTransform: { Dictionary(zip($0, $0), uniquingKeysWith: { $1 }) }, 
                    encodeTransform: { $0.values }
                )
                var a: [Int:Int]
            }
            """, 
            expandedSource: #"""
            struct Test {
                var a: [Int:Int]
            }

            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath = "path"
                }
                enum $__coding_container_keys_root_path_root: String, CodingKey {
                    case kinner = "inner"
                }
                enum $__coding_container_keys_root_path_root_inner: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    do {
                        let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                        do {
                            var $__coding_container_root_path = try $__coding_container_root.nestedUnkeyedContainer(
                                forKey: .kpath
                            )
                            var $__sequence_coding_temp_a = $__coding_make_empty_array(ofType: Int.self)
                            while !$__coding_container_root_path.isAtEnd {
                                do {
                                    let $__coding_container_root_path_root = try $__coding_container_root_path.nestedContainer(
                                        keyedBy: $__coding_container_keys_root_path_root.self
                                    )
                                    do {
                                        let $__coding_container_root_path_root_inner = try $__coding_container_root_path_root.nestedContainer(
                                            keyedBy: $__coding_container_keys_root_path_root_inner.self,
                                            forKey: .kinner
                                        )
                                        do {
                                            let rawValue = try $__coding_container_root_path_root_inner.decode(
                                                Int.self,
                                                forKey: .ka
                                            )
                                            $__sequence_coding_temp_a.append(rawValue)
                                        } catch Swift.DecodingError.keyNotFound, Swift.DecodingError.valueNotFound {
                                            $__sequence_coding_temp_a.append(-1)
                                        } catch Swift.DecodingError.typeMismatch {
                                        }
                                    } catch Swift.DecodingError.keyNotFound {
                                        $__sequence_coding_temp_a.append(-1)
                                    } catch Swift.DecodingError.typeMismatch {
                                    }
                                } catch Swift.DecodingError.keyNotFound {
                                    $__sequence_coding_temp_a.append(-1)
                                    try $__coding_container_root_path.skip()
                                } catch Swift.DecodingError.typeMismatch {
                                    try $__coding_container_root_path.skip()
                                }
                            }
                            do {
                                let rawValue = try $__coding_transform($__sequence_coding_temp_a, {
                                        Dictionary(zip($0, $0), uniquingKeysWith: {
                                                $1
                                            })
                                    })
                                let value = rawValue
                                self.a = value
                            }
                        } catch Swift.DecodingError.typeMismatch {
                            self.a = [2: 2]
                        } catch Swift.DecodingError.keyNotFound {
                            self.a = [1: 1]
                        }
                    } catch Swift.DecodingError.typeMismatch {
                        self.a = [2: 2]
                    } catch Swift.DecodingError.keyNotFound {
                        self.a = [1: 1]
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        var $__coding_container_root_path = $__coding_container_root.nestedUnkeyedContainer(
                            forKey: .kpath
                        )
                        let $__sequence_coding_temp_a = try { () throws in
                            let transformedValue = self.a
                            return try $__coding_transform(transformedValue, {
                                    $0.values
                                })
                        }()
                        for $__sequence_coding_element_a in $__sequence_coding_temp_a {
                            var $__coding_container_root_path_root = $__coding_container_root_path.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_root.self
                            )
                            var $__coding_container_root_path_root_inner = $__coding_container_root_path_root.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_root_inner.self,
                                forKey: .kinner
                            )
                            try $__coding_container_root_path_root_inner.encode(
                                $__sequence_coding_element_a,
                                forKey: .ka
                            )
                        }
                    }
                }
            }
            """#
        )
    }


    @Codable
    struct Test4 {
        @CodingField("path", onMissing: [1:1], onMismatch: [2:2])
        @SequenceCodingField(
            subPath: "inner", "a", 
            elementEncodedType: Int.self, 
            default: .value(1),
            decodeTransform: { Dictionary(zip($0, $0), uniquingKeysWith: { $1 }) }, 
            encodeTransform: { $0.values }
        )
        var a: [Int:Int]
    }

    @Test
    func test4() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path", onMissing: [1:1], onMismatch: [2:2])
                @SequenceCodingField(
                    subPath: "inner", "a", 
                    elementEncodedType: Int.self, 
                    default: .value(1),
                    decodeTransform: { Dictionary(zip($0, $0), uniquingKeysWith: { $1 }) }, 
                    encodeTransform: { $0.values }
                )
                var a: [Int:Int]
            }
            """, 
            expandedSource: #"""
            struct Test {
                var a: [Int:Int]
            }

            extension Test: Codable {
                enum $__coding_container_keys_root: String, CodingKey {
                    case kpath = "path"
                }
                enum $__coding_container_keys_root_path_root: String, CodingKey {
                    case kinner = "inner"
                }
                enum $__coding_container_keys_root_path_root_inner: String, CodingKey {
                    case ka = "a"
                }
                public init(from decoder: Decoder) throws {
                    \#(transformFunctionDefinition())
                    \#(validateFunctionDefinition())
                    \#(makeEmptyArrayFunctionDefinition())
                    do {
                        let $__coding_container_root = try decoder.container(keyedBy: $__coding_container_keys_root.self)
                        do {
                            var $__coding_container_root_path = try $__coding_container_root.nestedUnkeyedContainer(
                                forKey: .kpath
                            )
                            var $__sequence_coding_temp_a = $__coding_make_empty_array(ofType: Int.self)
                            while !$__coding_container_root_path.isAtEnd {
                                do {
                                    let $__coding_container_root_path_root = try $__coding_container_root_path.nestedContainer(
                                        keyedBy: $__coding_container_keys_root_path_root.self
                                    )
                                    do {
                                        let $__coding_container_root_path_root_inner = try $__coding_container_root_path_root.nestedContainer(
                                            keyedBy: $__coding_container_keys_root_path_root_inner.self,
                                            forKey: .kinner
                                        )
                                        do {
                                            let rawValue = try $__coding_container_root_path_root_inner.decode(
                                                Int.self,
                                                forKey: .ka
                                            )
                                            $__sequence_coding_temp_a.append(rawValue)
                                        } catch Swift.DecodingError.keyNotFound, Swift.DecodingError.valueNotFound {
                                            $__sequence_coding_temp_a.append(1)
                                        } catch Swift.DecodingError.typeMismatch {
                                            $__sequence_coding_temp_a.append(1)
                                        }
                                    } catch Swift.DecodingError.keyNotFound {
                                        $__sequence_coding_temp_a.append(1)
                                    } catch Swift.DecodingError.typeMismatch {
                                        $__sequence_coding_temp_a.append(1)
                                    }
                                } catch Swift.DecodingError.keyNotFound {
                                    $__sequence_coding_temp_a.append(1)
                                    try $__coding_container_root_path.skip()
                                } catch Swift.DecodingError.typeMismatch {
                                    $__sequence_coding_temp_a.append(1)
                                    try $__coding_container_root_path.skip()
                                }
                            }
                            do {
                                let rawValue = try $__coding_transform($__sequence_coding_temp_a, {
                                        Dictionary(zip($0, $0), uniquingKeysWith: {
                                                $1
                                            })
                                    })
                                let value = rawValue
                                self.a = value
                            }
                        } catch Swift.DecodingError.typeMismatch {
                            self.a = [2: 2]
                        } catch Swift.DecodingError.keyNotFound {
                            self.a = [1: 1]
                        }
                    } catch Swift.DecodingError.typeMismatch {
                        self.a = [2: 2]
                    } catch Swift.DecodingError.keyNotFound {
                        self.a = [1: 1]
                    }
                }
                public func encode(to encoder: Encoder) throws {
                    \#(transformFunctionDefinition())
                    var $__coding_container_root = encoder.container(keyedBy: $__coding_container_keys_root.self)
                    do {
                        var $__coding_container_root_path = $__coding_container_root.nestedUnkeyedContainer(
                            forKey: .kpath
                        )
                        let $__sequence_coding_temp_a = try { () throws in
                            let transformedValue = self.a
                            return try $__coding_transform(transformedValue, {
                                    $0.values
                                })
                        }()
                        for $__sequence_coding_element_a in $__sequence_coding_temp_a {
                            var $__coding_container_root_path_root = $__coding_container_root_path.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_root.self
                            )
                            var $__coding_container_root_path_root_inner = $__coding_container_root_path_root.nestedContainer(
                                keyedBy: $__coding_container_keys_root_path_root_inner.self,
                                forKey: .kinner
                            )
                            try $__coding_container_root_path_root_inner.encode(
                                $__sequence_coding_element_a,
                                forKey: .ka
                            )
                        }
                    }
                }
            }
            """#
        )
    }


    // @Codable
    // struct TestE1 {
    //     @CodingField("path1", "path2")
    //     @SequenceCodingField(subPath: "path3", "field", elementEncodedType: Int.self)
    //     var a: [Int]
    //     @CodingField("path1", "path2")
    //     @SequenceCodingField(subPath: "path3", elementEncodedType: String.self)
    //     var b: [String]
    // }

    @Test
    func testE1() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @CodingField("path1", "path2")
                @SequenceCodingField(subPath: "path3", "field", elementEncodedType: Int.self)
                var a: [Int]
                @CodingField("path1", "path2")
                @SequenceCodingField(subPath: "path3", elementEncodedType: String.self)
                var b: [String]
            }
            """, 
            expandedSource: """
            struct Test {
                var a: [Int]
                var b: [String]
            }
            """,
            diagnostics: [
                .init(
                    message: #"Property has path that conflict with that of another property"#,
                    line: 8,
                    column: 9,
                    notes: [
                        .init(
                            message: "Any two properties in the same type must not have the same coding path or having path that is a prefix of the the path of the other",
                            line: 8,
                            column: 9
                        ),
                        .init(
                            message: #"conflicted with the path of property "a""#,
                            line: 5,
                            column: 9
                        )
                    ]
                ),
                .init(
                    message: #"path of "b" conflicts with path of this property"#,
                    line: 5,
                    column: 9
                )
            ]
        )
    }


    // @Codable
    // struct TestE2 {
    //     @SequenceCodingField(elementEncodedType: Int.self, default: .ignore)
    //     @SequenceCodingField(subPath: "a", elementEncodedType: Int.self, default: .value(1))
    //     var a: [Int]
    // }

    @Test
    func testE2() async throws {
        assertMacroExpansion(
            source: """
            @Codable
            struct Test {
                @SequenceCodingField(elementEncodedType: Int.self, default: .ignore)
                @SequenceCodingField(subPath: "a", elementEncodedType: Int.self, default: .value(1))
                var a: [Int]
            }
            """, 
            expandedSource: """
            struct Test {
                var a: [Int]
            }
            """,
            diagnostics: [
                .init(message: .decorator.general.duplicateMacro(name: "SequenceCodingField"), line: 5, column: 9)
            ]
        )
    }


    // @Codable 
    // struct TestE3 {
    //     @SequenceCodingField(elementEncodedType: Int.self)
    //     var a: [Int] {
    //         return []
    //     }
    // }

    @Test 
    func testE3() async throws {
        assertMacroExpansion(
            source: """
            @Codable 
            struct Test {
                @SequenceCodingField(elementEncodedType: Int.self)
                var a: [Int] {
                    return []
                }
            }
            """, 
            expandedSource: """
            struct Test {
                var a: [Int] {
                    return []
                }
            }
            """,
            diagnostics: [
                .init(message: .decorator.general.attachTypeError, line: 4, column: 9)
            ]
        )
    }

}