//
//  Tags.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/24.
//

import Testing


extension Tag {
    
    enum coding {
        @Tag static var keyedCoding: Tag
        @Tag static var singleValueCoding: Tag
    }
    
}
