import SwiftSyntax
import SwiftSyntaxBuilder



extension EnumCodableMacro {

    struct UnkeyedGenerator: Generator {

        let caseCodingSpecList: [UnkeyedCaseCodingSpec]

    }

}



extension EnumCodableMacro.UnkeyedGenerator {

    func generateCodingKeys() throws -> [DeclSyntax] {

        try buildDeclSyntaxList {

            let allObjectPayloadKeys = caseCodingSpecList.reduce(into: Set<String>()) { acc, spec in
                switch spec.payload {
                    case .content(.object(let keys)): acc.formUnion(keys.map(\.trimmedDescription))
                    default: break
                }
            }

            if !allObjectPayloadKeys.isEmpty {
                try EnumDeclSyntax("enum \(rootCodingKeyDefName): String, CodingKey") {
                    "case \(raw: allObjectPayloadKeys.sorted().map { #"k\#($0) = "\#($0)""# }.joined(separator: ", "))"
                }
            }

        }
        
    }


    func generateDecodeInitializer() throws -> InitializerDeclSyntax {
        
        return try .init("public init(from decoder: Decoder) throws") {

            let specsWithObjectPayload = caseCodingSpecList.filter { if case .content(.object) = $0.payload { true } else { false } }
            let specsWithArrayPayload = caseCodingSpecList.filter { if case .content(.array) = $0.payload { true } else { false } }
            let specsWithSingleValuePayload = caseCodingSpecList.filter { if case .content(.singleValue) = $0.payload { true } else { false } }
            let specsWithRawValuePayload = caseCodingSpecList.filter { if case .rawValue = $0.payload { true } else { false } }

            if !specsWithSingleValuePayload.isEmpty || !specsWithRawValuePayload.isEmpty {

                try IfExprSyntax("if let container = try? decoder.singleValueContainer()") {

                    let groupedSpecs = specsWithRawValuePayload.reduce(
                        into: [String:[(EnumCaseUnkeyedCodingSpec, LiteralValue)]]()
                    ) { acc, spec in
                        if case .rawValue(let type, let value) = spec.payload {
                            acc[type.trimmedDescription, default: []].append((spec, value))
                        }
                    }

                    for (typeStr, specs) in groupedSpecs.sorted(by: { $0.key < $1.key }) {

                        try SwitchExprSyntax("switch try? container.decode(\(raw: typeStr).self)") {
                            for (spec, value) in specs {
                                SwitchCaseSyntax("case \(value.completeExpr.trimmed):") {
                                    "self = .\(spec.enumCaseInfo.name.trimmed)"
                                    "return"
                                }
                            }
                            "default: break"
                        }

                    }

                    for spec in specsWithSingleValuePayload {

                        switch spec.payload {
                            case .content(.singleValue): do {
                                let type = spec.enumCaseInfo.associatedValues[0].type
                                try IfExprSyntax("if let value = try? container.decode(\(type.trimmed).self)") {
                                    generateSelfAssignment(for: spec.enumCaseInfo, payloadContent: .singleValue)
                                    "return"
                                }
                            }
                            default: do {
                                // Handle by other blocks
                            }
                        }

                    }
                    
                }

            }

            if !specsWithArrayPayload.isEmpty {

                try IfExprSyntax("if var container = try? decoder.unkeyedContainer()") {

                    for spec in specsWithArrayPayload {

                        try DoStmtSyntax("do") {

                            switch spec.payload {
                                case .content(.array): do {
                                    makeDecodeItemsForArrayPayload(caseInfo: spec.enumCaseInfo, containerVarName: "container")
                                    generateSelfAssignment(for: spec.enumCaseInfo, payloadContent: .array)
                                }
                                default: do {
                                    // Handle by other blocks
                                }
                            }

                            "return"

                        }.addingCatchClause(errors: []) {}    

                    }

                    if !specsWithObjectPayload.isEmpty {
                        noMatchCaseFoundFallbackStatements
                    }

                }

            }

            if !specsWithObjectPayload.isEmpty {

                try IfExprSyntax("if let container = try? decoder.container(keyedBy: \(rootCodingKeyDefName).self)") {

                    for spec in specsWithObjectPayload {

                        try DoStmtSyntax("do") {

                            switch spec.payload {
                                case .content(.object(let objectPayloadKeys)): do {
                                    makeDecodeItemsForObjectPayload(caseInfo: spec.enumCaseInfo, containerVarName: "container", keys: objectPayloadKeys)
                                    generateSelfAssignment(for: spec.enumCaseInfo, payloadContent: .object(keys: objectPayloadKeys))
                                }
                                default: do {
                                    // Handle by other blocks
                                }
                            }

                            "return"

                        }.addingCatchClause(errors: []) {}

                    }

                }

            }

            noMatchCaseFoundFallbackStatements

        }

    }


    func generateEncodeMethod() throws -> FunctionDeclSyntax {
        
        return try .init("public func encode(to encoder: Encoder) throws") {

            try SwitchExprSyntax("switch self") {

                for spec in caseCodingSpecList {

                    let valueBindingList = (0 ..< spec.enumCaseInfo.associatedValues.count).map { "value\($0)" }
                    let valueBindingListStr = valueBindingList.joined(separator: ", ")

                    switch spec.payload {
                        case .rawValue(let type, let value): do {
                            SwitchCaseSyntax("case .\(spec.enumCaseInfo.name.trimmed):") {
                                "var container = encoder.singleValueContainer()"
                                "try container.encode(\(value.completeExpr) as \(type.trimmed))"
                            }
                        }
                        case .content(.singleValue): do {
                            SwitchCaseSyntax("case let .\(spec.enumCaseInfo.name.trimmed)(value):") {
                                "var container = encoder.singleValueContainer()"
                                "try container.encode(value)"
                            }
                        }
                        case .content(.array): do {
                            SwitchCaseSyntax("case let .\(spec.enumCaseInfo.name.trimmed)(\(raw: valueBindingListStr)):") {
                                "var container = encoder.unkeyedContainer()"
                                for valueBinding in valueBindingList {
                                    "try container.encode(\(raw: valueBinding))"
                                }
                            }
                        }
                        case .content(.object(let objectPayloadKeys)): do {
                            SwitchCaseSyntax("case let .\(spec.enumCaseInfo.name.trimmed)(\(raw: valueBindingListStr)):") {
                                "var container = encoder.container(keyedBy: \(rootCodingKeyDefName).self)"
                                for (valueBinding, objectPayloadKey) in zip(valueBindingList, objectPayloadKeys) {
                                    "try container.encode(\(raw: valueBinding), forKey: .k\(objectPayloadKey.trimmed))"
                                }
                            }
                        }
                    }

                }

            }

        }

    }

}