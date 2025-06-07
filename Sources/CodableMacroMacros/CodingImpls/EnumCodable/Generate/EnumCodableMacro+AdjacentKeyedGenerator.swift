import SwiftSyntax
import SwiftSyntaxBuilder



extension EnumCodableMacro {

    struct AdjucentKeyedGenerator: Generator {

        let caseCodingInfoList: [KeyedCaseCodingSpec]
        let typeKey: TokenSyntax
        let payloadKey: TokenSyntax

    }

}



extension EnumCodableMacro.AdjucentKeyedGenerator {


    func generateCodingKeys() throws -> [DeclSyntax] {

        try buildDeclSyntaxList {

            if caseCodingInfoList.contains(where: { $0.payload == .empty(.emptyObject) }) {
                unconditionalCodingKeysDef
            }
            
            try EnumDeclSyntax("enum \(rootCodingKeyDefName): String, CodingKey") {
                #"case k\#(typeKey) = "\#(typeKey)", k\#(payloadKey) = "\#(payloadKey)""#
            }

            for enumCaseCodingSpec in caseCodingInfoList {

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

            "let container = try decoder.container(keyedBy: \(rootCodingKeyDefName).self)"

            let specsWithStringKey = caseCodingInfoList.filter { $0.key.kind == .string }
            let specsWithNumberKey = caseCodingInfoList.filter { $0.key.kind == .int || $0.key.kind == .float }

            if !specsWithStringKey.isEmpty {
                try IfExprSyntax("if let type = try? container.decode(String.self, forKey: .k\(typeKey))") {
                    try decodeItems(from: specsWithStringKey)
                    if !specsWithNumberKey.isEmpty {
                        noMatchCaseFoundFallbackStatements
                    }
                }
            }

            if !specsWithNumberKey.isEmpty {
                try IfExprSyntax("if let type = try? container.decode(Double.self, forKey: .k\(typeKey))") {
                    try decodeItems(from: specsWithNumberKey)
                }
            }

            noMatchCaseFoundFallbackStatements

        }

    }


    func generateEncodeMethod() throws -> FunctionDeclSyntax {

        return try .init("public func encode(to encoder: Encoder) throws") {

            "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"

            try SwitchExprSyntax("switch self") {

                for spec in caseCodingInfoList {

                    switch spec.payload {

                        case .empty(let emptyPayloadOption): do {

                            SwitchCaseSyntax("case .\(spec.enumCaseInfo.name.trimmed):") {

                                "try container.encode(\(spec.key.completeExpr.trimmed), forKey: .k\(typeKey))"

                                switch emptyPayloadOption {
                                    case .nothing: do {
                                        // no need to encode payload
                                    }
                                    case .null: do {
                                        "try container.encodeNil(forKey: .k\(payloadKey))"
                                    }
                                    case .emptyArray: do {
                                        "try container.encode([DummyDecodableType](), forKey: .k\(payloadKey))"
                                    }
                                    case .emptyObject: do {
                                        "try container.encode(DummyDecodableType(), forKey: .k\(payloadKey))"
                                    }
                                }

                            }

                        }

                        case .content(let payloadContent): do {

                            let valueBindingList = (0 ..< spec.enumCaseInfo.associatedValues.count).map { "value\($0)" }
                            let valueBindingListStr = valueBindingList.joined(separator: ", ")

                            SwitchCaseSyntax("case let .\(spec.enumCaseInfo.name.trimmed)(\(raw: valueBindingListStr)):") {

                                "try container.encode(\(spec.key.completeExpr.trimmed), forKey: .k\(typeKey))"

                                switch payloadContent {
                                    case .singleValue: do {
                                        "try container.encode(value0, forKey: .k\(payloadKey))"
                                    }
                                    case .array: do {
                                        "var nestedContainer = container.nestedUnkeyedContainer(forKey: .k\(payloadKey))"
                                        for valueBinding in valueBindingList {
                                            "try nestedContainer.encode(\(raw: valueBinding))"
                                        }
                                    }
                                    case .object(let objectPayloadKeys): do {
                                        let objectPayloadKeyDefName = objectPayloadCodingKeyDefName(of: spec.enumCaseInfo.name.trimmed)
                                        "var nestedContainer = container.nestedContainer(keyedBy: \(objectPayloadKeyDefName).self, forKey: .k\(payloadKey))"
                                        for (valueBinding, objectPayloadKey) in zip(valueBindingList, objectPayloadKeys) {
                                            "try nestedContainer.encode(\(raw: valueBinding), forKey: .k\(objectPayloadKey.trimmed))"
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


    private func decodeItems(from enumCaseCodingSpecs: [EnumCaseKeyedCodingSpec]) throws -> SwitchExprSyntax {

        return try .init("switch type") {

            for spec in enumCaseCodingSpecs {

                try SwitchCaseSyntax(#"case \#(spec.key.completeExpr.trimmed):"#) {

                    switch spec.payload {
                        case .empty(let emptyPayloadOption): do {
                            try makeDecodeItemsForEmptyPayload(
                                caseInfo: spec.enumCaseInfo, 
                                type: emptyPayloadOption, 
                                parentContainerVarName: "container", 
                                key: ".k\(payloadKey)"
                            )
                        }
                        case .content(let payloadContent): do {
                            makeDecodeItemsForKeyedPayload(
                                caseInfo: spec.enumCaseInfo, 
                                payloadContent: payloadContent, 
                                parentContainerVarName: "container", 
                                key: ".k\(payloadKey)"
                            )
                        }
                    }

                }

            }

            "default: break"

        }

    }



    private func makeDecodeItemsForKeyedPayload(
        caseInfo: EnumCaseInfo,
        payloadContent: EnumCodableMacro.PayloadContent,
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
        type: EnumCodableMacro.EmptyPayloadOption,
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
