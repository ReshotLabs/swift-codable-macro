//
//  KeyDecodingStrategyCodingTest.swift
//  CodableMacro
//
//  Created by Claude on 2025/7/28.
//

import Testing
@testable import CodableMacro
import Foundation


extension CodingTest {
    
    @Suite("Test KeyDecodingStrategy in Actual Coding", .tags(.coding.keyedCoding))
    final class KeyDecodingStrategyCodingTest: CodingTest {}
    
}


extension CodingTest.KeyDecodingStrategyCodingTest {
    
    @Codable(keyDecodingStrategy: .convertFromSnakeCase)
    struct GameConfig: Equatable {
        @CodingField(onMissing: true)
        var hidePartyGames: Bool
        
        @CodingField(onMissing: 125)
        var pickupRadius: Double
        
        var displayName: String
        
        @CodingField(onMissing: false)
        var enableBuildingFilters: Bool
    }
    
    @Codable(keyDecodingStrategy: .useDefaultKeys)
    struct DefaultKeyConfig: Equatable {
        var hidePartyGames: Bool
        var displayName: String
    }
    
    @Test(
        "Test convertFromSnakeCase Decoding",
        arguments: [
            (
                .success(.init(hidePartyGames: false, pickupRadius: 250, displayName: "Test Config", enableBuildingFilters: true)),
                [
                    "hide_party_games": false,
                    "pickup_radius": 250,
                    "display_name": "Test Config",
                    "enable_building_filters": true
                ]
            ),
            (
                .success(.init(hidePartyGames: true, pickupRadius: 125, displayName: "Default Config", enableBuildingFilters: false)),
                [
                    "display_name": "Default Config"
                ]
            ),
            (
                .success(.init(hidePartyGames: false, pickupRadius: 300, displayName: "Partial Config", enableBuildingFilters: false)),
                [
                    "hide_party_games": false,
                    "pickup_radius": 300,
                    "display_name": "Partial Config"
                ]
            )
        ] as [(DecodeResult<GameConfig>, JsonComponent)]
    )
    func testConvertFromSnakeCaseDecoding(_ expectedInstance: DecodeResult<GameConfig>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    @Test(
        "Test convertFromSnakeCase Encoding",
        arguments: [
            (
                .init(hidePartyGames: false, pickupRadius: 250, displayName: "Test Config", enableBuildingFilters: true),
                [
                    "hide_party_games": false,
                    "pickup_radius": 250,
                    "display_name": "Test Config",
                    "enable_building_filters": true
                ]
            ),
            (
                .init(hidePartyGames: true, pickupRadius: 125, displayName: "Default Config", enableBuildingFilters: false),
                [
                    "hide_party_games": true,
                    "pickup_radius": 125,
                    "display_name": "Default Config",
                    "enable_building_filters": false
                ]
            )
        ] as [(GameConfig, JsonComponent)]
    )
    func testConvertFromSnakeCaseEncoding(_ instance: GameConfig, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
    @Test(
        "Test useDefaultKeys Decoding",
        arguments: [
            (
                .success(.init(hidePartyGames: false, displayName: "Test Config")),
                [
                    "hidePartyGames": false,
                    "displayName": "Test Config"
                ]
            ),
            (
                .error,
                [
                    "hide_party_games": false,  // snake_case won't work with useDefaultKeys
                    "display_name": "Test Config"
                ]
            )
        ] as [(DecodeResult<DefaultKeyConfig>, JsonComponent)]
    )
    func testUseDefaultKeysDecoding(_ expectedInstance: DecodeResult<DefaultKeyConfig>, _ json: JsonComponent) async throws {
        try codingTestDecodeAssert(expectedInstance, json)
    }
    
    @Test(
        "Test useDefaultKeys Encoding",
        arguments: [
            (
                .init(hidePartyGames: false, displayName: "Test Config"),
                [
                    "hidePartyGames": false,
                    "displayName": "Test Config"
                ]
            )
        ] as [(DefaultKeyConfig, JsonComponent)]
    )
    func testUseDefaultKeysEncoding(_ instance: DefaultKeyConfig, _ expectedJson: JsonComponent) async throws {
        try codingTestEncodeAssert(instance, expectedJson)
    }
    
}