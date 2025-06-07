import SwiftSyntax
import SwiftSyntaxBuilder


extension EnumCodableMacro {

    struct ExternalKeyedGenerator: Generator {
        let caseCodingInfoList: [KeyedCaseCodingSpec]
    }

}



extension EnumCodableMacro.ExternalKeyedGenerator {

    func generateCodingKeys() throws -> [DeclSyntax] {

        return try buildDeclSyntaxList {

            if caseCodingInfoList.contains(where: { $0.payload == .empty(.emptyObject) }) {
                unconditionalCodingKeysDef
            }

            let keys = caseCodingInfoList
                .filter { $0.payload != .empty(.nothing) }
                .compactMap(\.key.token)

            if !keys.isEmpty {
                try EnumDeclSyntax("enum \(rootCodingKeyDefName): String, CodingKey") {
                    for key in keys {
                        #"case k\#(key.trimmed) = "\#(key.trimmed)""#
                    }
                }
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

            let specsWithNoPayload = caseCodingInfoList.filter { $0.payload == .empty(.nothing) }
            let specsWithPayload = caseCodingInfoList.filter { $0.payload != .empty(.nothing) }

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

                        for spec in caseCodingInfoList where spec.payload != .empty(.nothing) {
                            
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

                for spec in caseCodingInfoList {

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
                                            "try nestedContainer.encode(\(raw: valueVarName), forKey: .k\(objectPayloadKey.trimmed))"
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