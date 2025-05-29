import SwiftSyntax
import SwiftSyntaxBuilder


extension EnumCodableMacro {

    struct ExternalKeyedGenerator: Generator {
        let enumCaseCodingSpecs: [EnumCaseKeyedCodingSpec]
    }

}



extension EnumCodableMacro.ExternalKeyedGenerator {

    func generateCodingKeys() throws -> [DeclSyntax] {

        return try buildDeclSyntaxList {

            if enumCaseCodingSpecs.contains(where: { $0.payload == .empty(.emptyObject) }) {
                unconditionalCodingKeysDef
            }

            let keys = enumCaseCodingSpecs
                .filter { $0.payload != .empty(.nothing) }
                .compactMap(\.key.token)

            if !keys.isEmpty {
                try EnumDeclSyntax("enum \(rootCodingKeyDefName): String, CodingKey") {
                    for key in keys {
                        #"case k\#(key.trimmed) = "\#(key.trimmed)""#
                    }
                }
            }

            for enumCaseCodingSpec in enumCaseCodingSpecs {

                if case let .content(.object(keys: objectPayloadKeys)) = enumCaseCodingSpec.payload {

                    try EnumDeclSyntax("enum \(objectPayloadCodingKeyDefName(of: enumCaseCodingSpec.enumCaseInfo.name.trimmed)): String, CodingKey") {
                        for key in objectPayloadKeys {
                            #"case k\#(key.trimmed) = "\#(key.trimmed)""#
                        }
                    }

                }

            }

        }

    }


    func generateDecodeInitializer() throws -> InitializerDeclSyntax {

        return try .init("public init(from decoder: Decoder) throws") {

            let specsWithNoPayload = enumCaseCodingSpecs.filter { $0.payload == .empty(.nothing) }
            let specsWithPayload = enumCaseCodingSpecs.filter { $0.payload != .empty(.nothing) }

            if !specsWithNoPayload.isEmpty {

                try IfExprSyntax("if let caseKey = try? decoder.singleValueContainer().decode(String.self)") {

                    try SwitchExprSyntax("switch caseKey") {
                        
                        for spec in specsWithNoPayload {
                            #"""
                            case "\#(spec.key.token.trimmed)":
                                self = .\#(spec.enumCaseInfo.name.trimmed)
                                return
                            """#
                        }

                        "default: break"

                    }

                    if !specsWithPayload.isEmpty {
                        noMatchCaseFoundFallbackStatements
                    }

                }

            }

            if !specsWithPayload.isEmpty {

                try IfExprSyntax("if let container = try? decoder.container(keyedBy: \(rootCodingKeyDefName).self)") {

                    """
                    guard container.allKeys.count == 1, let caseKey = container.allKeys.first else {
                        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "No matched case found"))
                    }
                    """

                    try SwitchExprSyntax("switch caseKey") {

                        for spec in enumCaseCodingSpecs where spec.payload != .empty(.nothing) {
                            
                            switch spec.payload {
                                case .empty(.nothing): do {
                                    // already handled, do nothing here
                                }
                                case .empty(let emptyPayloadOption): do {
                                    try SwitchCaseSyntax("case .k\(spec.key.token.trimmed):") {
                                        try makeDecodeItemsForEmptyPayload(
                                            caseInfo: spec.enumCaseInfo, 
                                            type: emptyPayloadOption, 
                                            parentContainerVarName: "container", 
                                            key: ".k\(spec.key.token.trimmed)"
                                        )
                                    }
                                }
                                case .content(let payloadContent): do {
                                    SwitchCaseSyntax("case .k\(spec.key.token.trimmed):") {
                                        makeDecodeItemsForKeyedPayload(
                                            caseInfo: spec.enumCaseInfo, 
                                            payloadContent: payloadContent, 
                                            parentContainerVarName: "container", 
                                            key: ".k\(spec.key.token.trimmed)"
                                        )
                                    }
                                }
                            }

                        }

                    }

                }

            }

            noMatchCaseFoundFallbackStatements

        }

    }


    func generateEncodeMethod() throws -> FunctionDeclSyntax {
        
        return try .init("public func encode(to encoder: Encoder) throws") {
            
            try SwitchExprSyntax("switch self") {

                for spec in enumCaseCodingSpecs {

                    switch spec.payload {

                        case .empty(let emptyPayloadOption): do {

                            SwitchCaseSyntax("case .\(spec.enumCaseInfo.name.trimmed):") {

                                switch emptyPayloadOption {
                                    case (.nothing): do {
                                        "var container = encoder.singleValueContainer()"
                                        #"try container.encode("\#(spec.key.token)")"#
                                    }
                                    case (.null): do {
                                        "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
                                        "try container.encodeNil(forKey: .k\(spec.key.token.trimmed))"
                                    }
                                    case (.emptyArray): do {
                                        "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
                                        "try container.encode([DummyDecodableType](), forKey: .k\(spec.key.token.trimmed))"
                                    }
                                    case (.emptyObject): do {
                                        "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
                                        "try container.encode(DummyDecodableType(), forKey: .k\(spec.key.token.trimmed))"
                                    }
                                }

                            }

                        }

                        case .content(let payloadContent): do {

                            let valueBindingList = (0 ..< spec.enumCaseInfo.associatedValues.count).map { "value\($0)" }
                            let valueBindingListStr = valueBindingList.joined(separator: ", ")

                            SwitchCaseSyntax("case let .\(spec.enumCaseInfo.name.trimmed)(\(raw: valueBindingListStr)):") {

                                switch payloadContent {
                                    case .singleValue: do {
                                        "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
                                        "try container.encode(value0, forKey: .k\(spec.key.token.trimmed))"
                                    }
                                    case .array: do {
                                        "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
                                        "var nestedContainer = container.nestedUnkeyedContainer(forKey: .k\(spec.key.token.trimmed))"
                                        for valueBinding in valueBindingList {
                                            "try nestedContainer.encode(\(raw: valueBinding))"
                                        }
                                    }
                                    case .object(let objectPayloadKeys): do {
                                        "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
                                        let codingKeysDefName = objectPayloadCodingKeyDefName(of: spec.enumCaseInfo.name.trimmed)
                                        "var nestedContainer = container.nestedContainer(keyedBy: \(codingKeysDefName).self, forKey: .k\(spec.key.token.trimmed))"
                                        for (valueVarName, objectPayloadKey) in zip(valueBindingList, objectPayloadKeys) {
                                            "try nestedContainer.encode(\(raw: valueVarName), forKey: .k\(objectPayloadKey))"
                                        }
                                    }
                                }

                            }

                        }

                    }

                }

            }

        }

    }


    private func makeDecodeItemsForKeyedPayload(
        caseInfo: EnumCaseInfo,
        payloadContent: PayloadContent,
        parentContainerVarName: TokenSyntax,
        key: ExprSyntax
    ) -> CodeBlockItemListSyntax {

        return .init {

            switch payloadContent {
                case .singleValue: do {
                    let associatedValue = caseInfo.associatedValues[0]
                    "let value = try \(parentContainerVarName).decode(\(associatedValue.type).self, forKey: \(key))"
                }
                case .array: do {
                    "var nestedContainer = try \(parentContainerVarName).nestedUnkeyedContainer(forKey: \(key))"
                    makeDecodeItemsForArrayPayload(caseInfo: caseInfo, containerVarName: "nestedContainer")
                }
                case .object(let objectPayloadKeys): do {
                    let codingKeysDefName = objectPayloadCodingKeyDefName(of: caseInfo.name.trimmed)
                    "let nestedContainer = try \(parentContainerVarName).nestedContainer(keyedBy: \(codingKeysDefName).self, forKey: \(key))"
                    makeDecodeItemsForObjectPayload(caseInfo: caseInfo, containerVarName: "nestedContainer", keys: objectPayloadKeys)
                }
            }

            generateSelfAssignment(for: caseInfo, payloadContent: payloadContent)
            "return"

        }

    }


    private func makeDecodeItemsForEmptyPayload(
        caseInfo: EnumCaseInfo,
        type: EmptyPayloadOption,
        parentContainerVarName: TokenSyntax,
        key: ExprSyntax
    ) throws -> CodeBlockItemListSyntax {

        return try .init {

            switch type {
                case .nothing: do {
                    "self = .\(caseInfo.name.trimmed)"
                    "return"
                }
                case .null: do {
                    try IfExprSyntax("if try \(parentContainerVarName).decodeNil(forKey: \(key))") {
                        "self = .\(caseInfo.name.trimmed)"
                        "return"
                    }
                }
                case .emptyArray: do {
                    "let nestedContainer = try \(parentContainerVarName).nestedUnkeyedContainer(forKey: \(key))"
                    try IfExprSyntax("if nestedContainer.count == 0") {
                        "self = .\(caseInfo.name.trimmed)"
                        "return"
                    }
                }
                case .emptyObject: do {
                    "let nestedContainer = try \(parentContainerVarName).nestedContainer(keyedBy: \(unconditionalCodingKeysDefName).self, forKey: \(key))"
                    try IfExprSyntax("if nestedContainer.allKeys.isEmpty") {
                        "self = .\(caseInfo.name.trimmed)"
                        "return"
                    }
                }
            }

        }

    }

}


// extension EnumCodableMacro {

//     private func generateDecodeItems(
//         for enumCaseCodingSpec: EnumCaseKeyedCodingSpec, 
//         matching matchingOption: EnumCaseCodingEmptyPayloadOption
//     ) throws -> CodeBlockItemListSyntax {

//         try .init {

//             switch matchingOption {
//                 case .null: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "_ = try container.decodeNil(forKey: .k\(key))"
//                         case .none: "_ = try decoder.singleValueContainer().decodeNil()"
//                     }
//                     "self = .\(enumCaseCodingSpec.enumCaseInfo.name)"
//                     "return"
//                 }
//                 case .emptyArray: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "let nestedContainer = try container.nestedUnkeyedContainer(forKey: .k\(key))"
//                         case .none: "let nestedContainer = try decoder.unkeyedContainer()"
//                     }
//                     try IfExprSyntax("if nestedContainer.count == 0") {
//                         "self = .\(enumCaseCodingSpec.enumCaseInfo.name)"
//                         "return"
//                     }
//                 }
//                 case .emptyObject: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "let nestedContainer = try container.nestedContainer(keyedBy: \(unconditionalCodingKeyDefName).self, forKey: .k\(key))"
//                         case .none: "let nestedContainer = try decoder.container(keyedBy: \(unconditionalCodingKeyDefName).self)"
//                     }
//                     try IfExprSyntax("if nestedContainer.allKeys.isEmpty") {
//                         "self = .\(enumCaseCodingSpec.enumCaseInfo.name)"
//                         "return"
//                     }
//                 }
//                 case .value(let type, let value): do {
//                     let decodeExpr = switch enumCaseCodingSpec.key {
//                         case .some(let key): "try container.decode(\(type.trimmed).self, forKey: .k\(key))"
//                         case .none: "try \(type.trimmed)(from: decoder)"
//                     } as ExprSyntax
//                     try IfExprSyntax("if \(decodeExpr) == \(value)") {
//                         "self = .\(enumCaseCodingSpec.enumCaseInfo.name)"
//                         "return"
//                     }
//                 }
//             }

//         }

//     }


//     private func generateDecodeItems(
//         for enumCaseCodingSpec: EnumCaseKeyedCodingSpec, 
//         retrieving retrievingOption: EnumCaseCodingPayloadContent
//     ) throws -> CodeBlockItemListSyntax {

//         let enumCaseInfo = enumCaseCodingSpec.enumCaseInfo

//         return try .init {
            
//             switch retrievingOption {
//                 case .singleValue: do {
//                     if enumCaseInfo.associatedValues.count != 1 {
//                         throw .diagnostic(node: enumCaseInfo.name, message: .codingMacro.enumCodable.mismatchedAssociatedValueForSingleValueRetriving())
//                     }
//                     let associatedValue = enumCaseInfo.associatedValues[0]
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "let value = try container.decode(\(associatedValue.type).self, forKey: .k\(key))"
//                         case .none: "let value = try decoder.singleValueContainer().decode(\(associatedValue.type).self)"
//                     }
//                     generateSelfAssignment(for: enumCaseInfo, retrievingOption: retrievingOption)
//                     "return"
//                 }
//                 case .array: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "var nestedContainer = try container.nestedUnkeyedContainer(forKey: .k\(key))"
//                         case .none: "var nestedContainer = try decoder.unkeyedContainer()"
//                     }
//                     for (i, associatedValue) in enumCaseInfo.associatedValues.enumerated() {
//                         "let value\(raw: i) = try nestedContainer.decode(\(associatedValue.type).self)"
//                     }
//                     generateSelfAssignment(for: enumCaseInfo, retrievingOption: retrievingOption)
//                     "return"
//                 }
//                 case .object(let keys): do {
//                     let codingKeysDefName = codingKeyDefName(of: enumCaseInfo.name)
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "let nestedContainer = try container.nestedContainer(keyedBy: \(codingKeysDefName).self, forKey: .k\(key))"
//                         case .none: "let nestedContainer = try decoder.container(keyedBy: \(codingKeysDefName).self)"
//                     }
//                     if enumCaseInfo.associatedValues.count != keys.count {
//                         throw .diagnostic(node: enumCaseCodingSpec.enumCaseInfo.name, message: .codingMacro.enumCodable.mismatchedKeyCountForObjectRetriving())
//                     }
//                     for (i, (associatedValue, key)) in zip(enumCaseInfo.associatedValues, keys).enumerated() {
//                         "let value\(raw: i) = try nestedContainer.decode(\(associatedValue.type).self, forKey: .k\(key))"
//                     }
//                     generateSelfAssignment(for: enumCaseInfo, retrievingOption: retrievingOption)
//                     "return"
//                 }
//             }

//         }

//     }


//     private func generateSelfAssignment(
//         for enumCaseInfo: EnumCaseInfo,
//         retrievingOption: EnumCaseCodingPayloadContent, 
//         decodedValueBaseVarName: TokenSyntax = "value"
//     ) -> CodeBlockItemSyntax {

//         switch retrievingOption {
//             case .singleValue: do {
//                 return switch enumCaseInfo.associatedValues[0].label {
//                     case .some(let label): "self = .\(enumCaseInfo.name)(\(label): \(decodedValueBaseVarName))"
//                     case .none: "self = .\(enumCaseInfo.name)(\(decodedValueBaseVarName))"
//                 }
//             }
//             case .array, .object: do {
//                 let assignmentStr = enumCaseInfo.associatedValues.enumerated().map { i, associatedValue in
//                     if let label = associatedValue.label {
//                         return "\(label): value\(i)"
//                     } else {
//                         return "value\(i)"
//                     }
//                 }.joined(separator: ", ")
//                 return "self = .\(enumCaseInfo.name)(\(raw: assignmentStr))"
//             }
//         }

//     }

// }



// extension EnumCodableMacro {

//     private func generateEncodeItems(
//         for enumCaseCodingSpec: EnumCaseKeyedCodingSpec, 
//         matching matchingOption: EnumCaseCodingEmptyPayloadOption
//     ) throws -> SwitchCaseSyntax {

//         return .init("case .\(enumCaseCodingSpec.enumCaseInfo.name):") {

//             if enumCaseCodingSpec.key != nil {
//                 "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
//             }

//             switch matchingOption {
//                 case .null: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "try container.encodeNil(forKey: .k\(key))"
//                         case .none: "try encoder.singleValueContainer().encodeNil()"
//                     }
//                 }
//                 case .emptyArray: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "try container.encode([DummyDecodableType](), forKey: .k\(key))"
//                         case .none: "try [DummyDecodableType]().encode(to: encoder)"
//                     }
//                 }
//                 case .emptyObject: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "try container.encode(DummyDecodableType(), forKey: .k\(key))"
//                         case .none: "try DummyDecodableType().encode(to: encoder)"
//                     }
//                 }
//                 case .value(_, let value): do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "try container.encode(\(value), forKey: .k\(key))"
//                         case .none: "try \(value).encode(to: encoder)"
//                     }
//                 }
//             }
            
//         }

//     }


//     private func generateEncodeItems(
//         for enumCaseCodingSpec: EnumCaseKeyedCodingSpec, 
//         retrieving retrievingOption: EnumCaseCodingPayloadContent
//     ) throws -> SwitchCaseSyntax {

//         let associatedValueBindingVarNameList = Array(0 ..< enumCaseCodingSpec.enumCaseInfo.associatedValues.count)
//             .map { "value\($0)" }

//         let associatedValueBindingStr = associatedValueBindingVarNameList.joined(separator: ", ")

//         return .init("case let .\(enumCaseCodingSpec.enumCaseInfo.name)(\(raw: associatedValueBindingStr)):") {

//             if enumCaseCodingSpec.key != nil {
//                 "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
//             }

//             switch retrievingOption {
//                 case .singleValue: do {
//                     let associatedValueVarName = associatedValueBindingVarNameList[0]
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "try container.encode(\(raw: associatedValueVarName), forKey: .k\(key))"
//                         case .none: "try \(raw: associatedValueVarName).encode(to: encoder)"
//                     }
//                 }
//                 case .array: do {
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "var nestedContainer = container.nestedUnkeyedContainer(forKey: .k\(key))"
//                         case .none: "var nestedContainer = encoder.unkeyedContainer()"
//                     }
//                     for associatedValueBindingVarName in associatedValueBindingVarNameList {
//                         "try nestedContainer.encode(\(raw: associatedValueBindingVarName))"
//                     }
//                 }
//                 case .object(let keys): do {
//                     let codingKeysDefName = codingKeyDefName(of: enumCaseCodingSpec.enumCaseInfo.name)
//                     switch enumCaseCodingSpec.key {
//                         case .some(let key): "var nestedContainer = container.nestedContainer(keyedBy: \(codingKeysDefName).self, forKey: .k\(key))"
//                         case .none: "var nestedContainer = encoder.container(keyedBy: \(codingKeysDefName).self)"
//                     }
//                     for (associatedValueBindingVarName, key) in zip(associatedValueBindingVarNameList, keys) {
//                         "try nestedContainer.encode(\(raw: associatedValueBindingVarName), forKey: .k\(key))"
//                     }
//                 }
//             }

//         }

//     }

// }