//
//  ParsingTest.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/7.
//

import Testing
@testable import CodableMacroMacros


@Suite("Test CodingField Parsing")
struct ParsingTest {
    
    @Test("Test Parsing CodingField Path")
    func parsing1() async throws {
        
//        let codingFieldInfoList = [
//            .init(fieldName: "foo", path: ["data", "data", "foo"]),
//            .init(fieldName: "creationTime", path: ["data", "metadata", "created_time"]),
//            .init(fieldName: "deletionTime", path: ["data", "metadata", "deletion_time"]),
//            .init(fieldName: "destroyed", path: ["data", "metadata", "destroyed"]),
//            .init(fieldName: "version", path: ["data", "metadata", "version"]),
//            .init(fieldName: "owner", path: ["data", "metadata", "custom_metadata", "owner"]),
//            .init(fieldName: "missionCritical", path: ["data", "metadata", "custom_metadata", "mission_critical"]),
//        ] as [CodingFieldMacro.CodingFieldInfo]
//        
//        let structure = try CodingStructure.parse(codingFieldInfoList)
//        
//        print(structure)
//        
//        #expect(
//            structure ==== .root(children: [
//                "data": .node(pathElement: "data", children: [
//                    "data": .node(pathElement: "data", children: [
//                        "foo": .leaf(pathElement: "foo", field: .init(name: "foo"))
//                    ], required: true),
//                    "metadata": .node(pathElement: "metadata", children: [
//                        "created_time": .leaf(pathElement: "created_time", field: .init(name: "creationTime")),
//                        "custom_metadata": .node(pathElement: "custom_metadata", children: [
//                            "owner": .leaf(pathElement: "owner", field: .init(name: "owner")),
//                            "mission_critical": .leaf(pathElement: "mission_critical", field: .init(name: "missionCritical"))
//                        ], required: true),
//                        "deletion_time": .leaf(pathElement: "deletion_time", field: .init(name: "deletionTime")),
//                        "destroyed": .leaf(pathElement: "destroyed", field: .init(name: "destroyed")),
//                        "version": .leaf(pathElement: "version", field: .init(name: "version"))
//                    ], required: true)
//                ], required: true)
//            ])
//        )
        
    }
    
}
