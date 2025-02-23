//
//  CodingTest.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/11.
//

//import Testing
//@testable import CodableMacro
//import Foundation
//
//
//@Suite("Test Encoding and Decoding")
//struct CodingTest {
//    
//    @Codable
//    struct SomeType: Equatable {
//        var field1: Int
//        var field2: Int?
//        var field3: Int = 1
//        @CodingField("path1", "path2", "field4")
//        var field4: Int
//        @CodingField("path1", "field5")
//        var field5: Int = 1
//        @CodingField("path1", "path2", "field6", default: 2)
//        var field6: Int = 1
//        @CodingField("path1", "path2", "field7")
//        var field7: Int?
//        @CodingField("path2", "field8")
//        let field8: Int = 1
//        @CodingIgnore
//        var fieldIgnore1: Int?
//        @CodingIgnore
//        var fieldIgnore2: Int = 1
//    }
//    
//    
//    @Test(
//        "Test Decoding",
//        arguments: [
//            (
//                .init(field1: 5, field2: 5, field3: 5, field4: 5, field5: 5, field6: 5, field7: 5),
//                [
//                    "field1": 5,
//                    "field2": 5,
//                    "field3": 5,
//                    "path1": [
//                        "path2": [
//                            "field4": 5,
//                            "field6": 5,
//                            "field7": 5
//                        ],
//                        "field5": 5
//                    ],
//                    "path2": [
//                        "field8": 1
//                    ],
//                    "path": ["not": ["exist": "something"]]
//                ]
//            ),
//            (
//                .init(field1: 5, field2: nil, field3: 1, field4: 5, field5: 1, field6: 2, field7: nil),
//                [
//                    "field1": 5,
//                    "path1": [
//                        "path2": [
//                            "field4": 5,
//                        ],
//                    ],
//                    "path": ["not": ["exist": "something"]]
//                ]
//            ),
//        ] as [(SomeType, JsonComponent)]
//    )
//    func deocde1(_ expectedInstance: SomeType, _ json: JsonComponent) async throws {
//        
//        let encoded = try JSONEncoder().encode(json)
//        let decoded = try JSONDecoder().decode(SomeType.self, from: encoded)
//        #expect(decoded == expectedInstance)
//        
//    }
//    
//    
//    @Test(
//        "Test Encoding",
//        arguments: [
//            (
//                .init(field1: 5, field2: 5, field3: 5, field4: 5, field5: 5, field6: 5, field7: 5),
//                [
//                    "field1": 5,
//                    "field2": 5,
//                    "field3": 5,
//                    "path1": [
//                        "path2": [
//                            "field4": 5,
//                            "field6": 5,
//                            "field7": 5
//                        ],
//                        "field5": 5
//                    ],
//                    "path2": [
//                        "field8": 1
//                    ]
//                ]
//            ),
//            (
//                .init(field1: 5, field2: nil, field3: 5, field4: 5, field5: 5, field6: 5, field7: nil),
//                [
//                    "field1": 5,
//                    "field2": nil,
//                    "field3": 5,
//                    "path1": [
//                        "path2": [
//                            "field4": 5,
//                            "field6": 5,
//                            "field7": nil
//                        ],
//                        "field5": 5
//                    ],
//                    "path2": [
//                        "field8": 1
//                    ]
//                ]
//            ),
//        ] as [(SomeType, JsonComponent)]
//    )
//    func encode1(_ instance: SomeType, _ expectedJson: JsonComponent) async throws {
//        let encoded = try JSONEncoder().encode(instance)
//        let decodedAsJsonComponent = try JSONDecoder().decode(JsonComponent.self, from: encoded)
//        #expect(decodedAsJsonComponent == expectedJson)
//    }
//    
//}
