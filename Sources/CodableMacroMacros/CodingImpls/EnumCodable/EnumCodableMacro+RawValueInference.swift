import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder
import Foundation



extension EnumCodableMacro {

    private static let supportedStringRawTypes: Set<String> = [
        "String"
    ]
    private static let supportedIntRawTypes: Set<String> = [
        "Int", "UInt", "Int8", "UInt8", "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64", "Int128", "UInt128",
    ]
    private static let supportedFloatRawTypes: Set<String> = [
        "Float", "Double", "Float16", "Float32", "Float64",
    ]


    static func inferRawValueType(from declGroup: DeclGroupSyntaxInfo) -> ExprSyntax? {
        guard let type = declGroup.inheritance.first?.as(IdentifierTypeSyntax.self) else { return nil }
        if declGroup.enumCases.contains(where: { $0.rawValue != nil }) {
            return .init(TypeExprSyntax(type: type))
        }
        if 
            Self.supportedStringRawTypes.contains(type.trimmedDescription) 
            || Self.supportedIntRawTypes.contains(type.trimmedDescription) 
            || Self.supportedFloatRawTypes.contains(type.trimmedDescription) 
        {
            return .init(TypeExprSyntax(type: type))
        }
        return nil
    }


    func extractEnumCaseInferredRawValues() -> (rawValues: [LiteralValue], type: ExprSyntax) {

        guard let rawValueType else { 
            return (declGroup.enumCases.map { .string($0.name) }, "String")
        }

        if Self.supportedStringRawTypes.contains(rawValueType.trimmedDescription) {

            return (
                declGroup.enumCases.map { $0.rawValue ?? .string($0.name) },
                rawValueType
            )

        } else if Self.supportedIntRawTypes.contains(rawValueType.trimmedDescription) {

            var counter = 0
            var rawValues = [LiteralValue]()

            for c in declGroup.enumCases {
                rawValues.append(c.rawValue ?? .int("\(raw: counter)"))
                counter = (c.rawValue?.resolvedValue.number.map(Int.init) ?? counter) + 1
            }

            return (rawValues, rawValueType)

        } else if Self.supportedFloatRawTypes.contains(rawValueType.trimmedDescription) {

            var counter = 0.0
            var rawValues = [LiteralValue]()

            for c in declGroup.enumCases {
                rawValues.append(c.rawValue ?? .float("\(raw: counter)"))
                counter = floor((c.rawValue?.resolvedValue.number) ?? counter)  + 1
            }

            return (rawValues, rawValueType)

        }

        return (declGroup.enumCases.map { .string($0.name) }, "String")

    }

}