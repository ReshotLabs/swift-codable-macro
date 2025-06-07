import SwiftSyntax


extension EnumCodableMacro {

    protocol Generator {

        func generateCodingKeys() throws -> [DeclSyntax]
        func generateDecodeInitializer() throws -> InitializerDeclSyntax
        func generateEncodeMethod() throws -> FunctionDeclSyntax

    }

}



extension EnumCodableMacro.Generator {

    typealias EnumCaseKeyedCodingSpec = EnumCodableMacro.KeyedCaseCodingSpec
    typealias EnumCaseUnkeyedCodingSpec = EnumCodableMacro.UnkeyedCaseCodingSpec

    var unconditionalCodingKeysDefName: TokenSyntax { "$__unconditional_coding_keys" }

    var unconditionalCodingKeysDef: DeclSyntax {
        #"""
        private struct \#(unconditionalCodingKeysDefName): CodingKey {
            init?(stringValue: String) {
                self.stringValue = stringValue
            }
            init?(intValue: Int) {
                self.intValue = intValue
                self.stringValue = "\(intValue)"
            }
            var intValue: Int?
            var stringValue: String
        }
        """#
    }

    var rootCodingKeyDefName: TokenSyntax { "$__coding_keys_root" }

    var noMatchCaseFoundFallbackStatements: CodeBlockItemListSyntax {
        .init {
            try! SwitchExprSyntax("switch Self.codingDefaultValue") {
                SwitchCaseSyntax("case .value(let defaultValue):") {
                    "self = defaultValue"
                    "return"
                }
                SwitchCaseSyntax("case .none:") {
                    "throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: \"No matched case found\"))"
                }
            }
        }
    }


    func objectPayloadCodingKeyDefName(of caseName: TokenSyntax) -> TokenSyntax {
        "\(rootCodingKeyDefName)_\(caseName)"
    }


    func generateSelfAssignment(
        for enumCaseInfo: EnumCaseInfo,
        payloadContent: EnumCodableMacro.PayloadContent, 
        decodedValueBaseVarName: TokenSyntax = "value"
    ) -> CodeBlockItemSyntax {

        switch payloadContent {
            case .singleValue: do {
                return switch enumCaseInfo.associatedValues[0].label {
                    case .some(let label): "self = .\(enumCaseInfo.name)(\(label): \(decodedValueBaseVarName))"
                    case .none: "self = .\(enumCaseInfo.name)(\(decodedValueBaseVarName))"
                }
            }
            case .array, .object: do {
                let assignmentStr = enumCaseInfo.associatedValues.enumerated().map { i, associatedValue in
                    if let label = associatedValue.label {
                        return "\(label): value\(i)"
                    } else {
                        return "value\(i)"
                    }
                }.joined(separator: ", ")
                return "self = .\(enumCaseInfo.name)(\(raw: assignmentStr))"
            }
        }

    }

}



extension EnumCodableMacro.Generator {

    func makeDecodeItemsForArrayPayload(
        caseInfo: EnumCaseInfo,
        containerVarName: TokenSyntax,
        decodedValueBaseVarName: TokenSyntax = "value"
    ) -> CodeBlockItemListSyntax {
        return .init {
            for (i, associatedValue) in caseInfo.associatedValues.enumerated() {
                "let value\(raw: i) = try \(containerVarName).decode(\(associatedValue.type.trimmed).self)"
            }
        }
    }


    func makeDecodeItemsForObjectPayload(
        caseInfo: EnumCaseInfo,
        containerVarName: TokenSyntax,
        keys: [EnumCodableMacro.ObjectPayloadKey],
        decodedValueBaseVarName: TokenSyntax = "value"
    ) -> CodeBlockItemListSyntax {
        return .init {
            for (i, (associatedValue, key)) in zip(caseInfo.associatedValues, keys).enumerated() {
                "let value\(raw: i) = try \(containerVarName).decode(\(associatedValue.type.trimmed).self, forKey: .k\(key.trimmed))"
            }
        }
    }

}