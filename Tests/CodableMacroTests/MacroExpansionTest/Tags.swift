//
//  Tags.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/22.
//

import Testing


extension Tag {
    
    enum expansion {
        @Tag static var keyedCoding: Tag
        @Tag static var singleValueCoding: Tag
        @Tag static var mutableProperty: Tag
        @Tag static var constantProperty: Tag
        @Tag static var optionalProperty: Tag
        @Tag static var initializerProperty: Tag
        @Tag static var macroDefaultValue: Tag
        @Tag static var computedProperty: Tag
    }
    
    enum coding {
        @Tag static var keyedCoding: Tag
        @Tag static var singleValueCoding: Tag
    }
    
}
