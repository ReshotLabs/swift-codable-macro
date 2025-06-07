import SwiftSyntax
import SwiftSyntaxBuilder



extension EnumCodableMacro {

    struct InternalKeyedGenerator: Generator {

        let caseCodingInfoList: [KeyedCaseCodingSpec]
        let typeKey: TokenSyntax

    }

}



extension EnumCodableMacro.InternalKeyedGenerator {

    func generateCodingKeys() throws -> [DeclSyntax] {
        
        try buildDeclSyntaxList {

            let allObjectPayloadKeys = caseCodingInfoList.reduce(into: Set<String>()) { acc, spec in
                switch spec.payload {
                    case .content(.object(let keys)): acc.formUnion(keys.map(\.trimmedDescription))
                    default: break
                }
            }

            try EnumDeclSyntax("enum \(rootCodingKeyDefName): String, CodingKey") {
                #"case k\#(typeKey) = "\#(typeKey)""#
                if (!allObjectPayloadKeys.isEmpty) {
                    "case \(raw: allObjectPayloadKeys.sorted().map { #"k\#($0) = "\#($0)""# }.joined(separator: ", "))"
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
                    try makeDecodeItems(for: specsWithStringKey)
                    if !specsWithNumberKey.isEmpty {
                        noMatchCaseFoundFallbackStatements
                    }
                }
            }

            if !specsWithNumberKey.isEmpty {
                try IfExprSyntax("if let type = try? container.decode(Double.self, forKey: .k\(typeKey))") {
                    try makeDecodeItems(for: specsWithNumberKey)
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
                        case .empty: do {
                            SwitchCaseSyntax("case .\(spec.enumCaseInfo.name.trimmed):") {
                                "try container.encode(\(spec.key.completeExpr.trimmed), forKey: .k\(typeKey))"
                            }
                        }
                        case .content(.object(let objectPayloadKeys)): do {

                            let valueBindingList = (0 ..< spec.enumCaseInfo.associatedValues.count).map { "value\($0)" }
                            let valueBindingListStr = valueBindingList.joined(separator: ", ")

                            SwitchCaseSyntax("case let .\(spec.enumCaseInfo.name.trimmed)(\(raw: valueBindingListStr)):") {
                                "try container.encode(\(spec.key.completeExpr.trimmed), forKey: .k\(typeKey))"
                                for (valueBinding, objectPayloadKey) in zip(valueBindingList, objectPayloadKeys) {
                                    "try container.encode(\(raw: valueBinding), forKey: .k\(objectPayloadKey.trimmed))"
                                }
                            }
                            
                        }
                        default: do {
                            // should never reach here
                        }
                    }

                }

            }

        }

    }


    private func makeDecodeItems(for specs: [EnumCaseKeyedCodingSpec]) throws -> CodeBlockItemListSyntax {

        return try .init {

            try SwitchExprSyntax("switch type") {

                for spec in specs {

                    SwitchCaseSyntax("case \(spec.key.completeExpr.trimmed):") {

                        switch spec.payload {
                            case .empty: do {
                                "self = .\(spec.enumCaseInfo.name.trimmed)"
                                "return"
                            }
                            case .content(.object(let objectPayloadKeys)): do {
                                makeDecodeItemsForObjectPayload(caseInfo: spec.enumCaseInfo, containerVarName: "container", keys: objectPayloadKeys)
                                generateSelfAssignment(for: spec.enumCaseInfo, payloadContent: .object(keys: objectPayloadKeys))
                                "return"
                            }
                            default: do {
                                // should never reach here
                            }
                        }

                    }

                }

                "default: break"

            }

        }

    }

}