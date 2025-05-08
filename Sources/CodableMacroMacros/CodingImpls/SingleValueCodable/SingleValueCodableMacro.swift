//
//  SingleValueCodableMacro.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/2/2.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


final class SingleValueCodableMacro: CodingMacroImplBase, CodingMacroImplProtocol {
    
    static let supportedAttachedTypes: Set<AttachedType> = [.class, .struct]

    static let macroArgumentsParsingRule: [ArgumentsParsingRule] = [
        .labeled("inherit", canIgnore: true)
    ]


    let inherit: Bool

    var shouldAutoInit: Bool {
        declGroup.type == .class
        && !inherit                                                 // no inherited Codable 
        && !declGroup.properties.contains(where: \.isRequired)      // all stored properties are initialized
        && !declGroup.hasInitializer                                // has no initializer
    }


    required init(macroNode: MacroInfo, declGroup: DeclGroupSyntaxInfo, context: any MacroExpansionContext) throws {
        if let inheritExpr = macroNode.arguments[0].first?.expression {
            guard let inheritBoolLiteralExpr = inheritExpr.as(BooleanLiteralExprSyntax.self) else {
                throw .diagnostic(node: inheritExpr, message: .codingMacro.singleValueCodable.notBoolLiteralArgument)
            }
            inherit = inheritBoolLiteralExpr.literal.tokenKind == .keyword(.true)
            if inherit && declGroup.type != .class {
                throw .diagnostic(node: inheritExpr, message: .codingMacro.singleValueCodable.valueTypeInherit)
            }
        } else {
            inherit = false
        }
        try super.init(macroNode: macroNode, declGroup: declGroup, context: context)
    }
    
    
    func makeExtensionHeader() throws -> SyntaxNodeString {
        if inherit {
            "extension \(declGroup.name.trimmed): InheritedSingleValueCodableProtocol"
        } else {
            "extension \(declGroup.name.trimmed): SingleValueCodableProtocol"
        }
    }
    
    
    func makeDecls() throws -> [DeclSyntax] {
        
        let delegateProperties = try declGroup.properties
            .compactMap { propertyInfo in
                let delegateAttributes = propertyInfo.attributes.filter {
                    guard let name = $0.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text else {
                        return false
                    }
                    return DecoratorMacros(rawValue: name) == .singleValueCodableDelegate
                }
                guard !delegateAttributes.isEmpty else { return nil as (PropertyInfo, ExprSyntax?)? }
                let defaultValue = try SingleValueCodableDelegateMacro.processProperty(propertyInfo, macroNodes: delegateAttributes)
                return (propertyInfo, defaultValue)
            }
        
        guard delegateProperties.count < 2 else {
            throw .diagnostic(node: declGroup.name, message: .codingMacro.singleValueCodable.multipleDelegates)
        }
        
        if let (delegateProperty, macroDefaultValue) = delegateProperties.first {
            return try makeDeclsWithDelegateProperty(delegateProperty, macroDefaultValue: macroDefaultValue)
        } else {
            return try makeDeclsWithoutDelegateProperty()
        }
        
    }

    
    
    enum Error {
        
        static let multipleDelegates: CodingMacroImplBase.Error = .init(
            id: "multiple_delegates",
            message: "A Type for SingleValueCodable should has no more than one stored property with SingleValueCodableDelegate"
        )
        
        static let unhandledRequiredProperties: CodingMacroImplBase.Error = .init(
            id: "unhandled_required_properties",
            message: "This property must be initialized in the decode initializer, which can't be done due to the property with SingleValueCodableDelegate"
        )

        static let missingSingleValueInitializer: CodingMacroImplBase.Error = .init(
            id: "missing_single_value_initializer",
            message: "The class that inherit Codable without delegate has no required single value initializer. Please make sure the parameter name is correctly named as `codingValue`"
        )

        static let notBoolLiteralArgument: CodingMacroImplBase.Error = .init(
            id: "not_bool_literal_argument",
            message: "The argument of SingleValueCodable should be a bool literal"
        )

        static let valueTypeInherit: CodingMacroImplBase.Error = .init(
            id: "value_type_inherit",
            message: "inherit parameter should not be true when the type is a value type"
        )
        
    }
    
}



extension SingleValueCodableMacro {

    private func makeDeclsWithoutDelegateProperty() throws -> [DeclSyntax] {

        if inherit {
            return try buildDeclSyntaxList {
                try makeDecodeInitDeclWithSingleValueInitBody()
                try makeEncodeFuncDecl()
            }
        } else {
            return []
        }

    }


    private func makeDeclsWithDelegateProperty(
        _ delegateProperty: PropertyInfo, 
        macroDefaultValue: ExprSyntax?
    ) throws -> [DeclSyntax] {

        try requireAllPropertiesInitialized(besides: [delegateProperty.name])

        return try buildDeclSyntaxList {

            try makeSingleValueEncodeFuncDecl(for: delegateProperty)
            try makeSingleValueDecodeInitDecl(for: delegateProperty)
            
            if let defaultValueExpr = try makeSingleValueDefaultValueExpr(for: delegateProperty, macroDefaultValue: macroDefaultValue) {
                try makeDefaultValueStaticPropertyDecl(for: delegateProperty, defaultValue: defaultValueExpr)
            }

            if inherit {
                try makeDecodeInitDecl(for: delegateProperty)
                try makeEncodeFuncDecl()
            }

            if shouldAutoInit {
                "public init() {}"
            }

        }

    }


    private func requireAllPropertiesInitialized(besides excludeProperties: Set<TokenSyntax>) throws {
        let requiredProperties = Set(declGroup.properties.filter(\.isRequired).map(\.name))
            .subtracting(excludeProperties)

        guard requiredProperties.isEmpty else {
            throw .diagnostics(
                requiredProperties.map { .init(node: $0, message: .codingMacro.singleValueCodable.unhandledRequiredProperties) }
            )
        }

    }


    private func makeSingleValueDefaultValueExpr(for delegateProperty: PropertyInfo, macroDefaultValue: ExprSyntax?) throws -> ExprSyntax? {
        if let macroDefaultValue {
            ".value(\(macroDefaultValue))" as ExprSyntax
        } else if let initializer = delegateProperty.initializer {
            ".value(\(initializer))" as ExprSyntax
        } else if delegateProperty.hasOptionalTypeDecl {
            ".value(nil)" as ExprSyntax
        } else {
            nil as ExprSyntax?
        }
    }


    private func makeSingleValueEncodeFuncDecl(for delegateProperty: PropertyInfo) throws -> DeclSyntax {

        guard let codingValueType = delegateProperty.dataType else {
            throw .diagnostic(node: delegateProperty.name, message: .codingMacro.general.missingExplicitType)
        }

        return """
            public func singleValueEncode() throws -> \(codingValueType) {
                return self.\(delegateProperty.name)
            }
            """

    }


    private func makeSingleValueDecodeInitDecl(for delegateProperty: PropertyInfo) throws -> InitializerDeclSyntax {

        guard let codingValueType = delegateProperty.dataType else {
            throw .diagnostic(node: delegateProperty.name, message: .codingMacro.general.missingExplicitType)
        }

        let canDecode = delegateProperty.type != .constant || delegateProperty.initializer == nil

        return switch (declGroup.type == .class, inherit) {
            case (_, true): try .init("public required init(from codingValue: \(codingValueType), decoder: Decoder) throws") {
                if canDecode { "self.\(delegateProperty.name) = codingValue" }
                "try super.init(from: decoder)"
            }
            case (true, false): try .init("public required init(from codingValue: \(codingValueType)) throws") {
                if canDecode { "self.\(delegateProperty.name) = codingValue" }
            }
            case (false, false): try .init("public init(from codingValue: \(codingValueType)) throws") {
                if canDecode { "self.\(delegateProperty.name) = codingValue" }
            }
        }
        
    }


    private func makeDefaultValueStaticPropertyDecl(for delegateProperty: PropertyInfo, defaultValue: ExprSyntax) throws -> DeclSyntax {

        guard let codingValueType = delegateProperty.dataType else {
            throw .diagnostic(node: delegateProperty.name, message: .codingMacro.general.missingExplicitType)
        }

        return """
            public static var singleValueCodingDefaultValue: SingleValueCodableDefaultValue<\(codingValueType)> {
                \(defaultValue)
            }
            """

    }


    private func makeDecodeInitDecl(for delegateProperty: PropertyInfo) throws -> InitializerDeclSyntax {
        let canDecode = delegateProperty.type != .constant || delegateProperty.initializer == nil
        return try InitializerDeclSyntax("public required init(from decoder: any Decoder) throws") {
            """
            let codingValue = switch Self.singleValueCodingDefaultValue {
                case .value(let defaultValue):
                    (try? CodingValue(from: decoder)) ?? defaultValue
                case .none:
                    try CodingValue(from: decoder)
            }
            """
            if canDecode {
                "self.\(delegateProperty.name) = codingValue"
            }
            if inherit {
                "try super.init(from: decoder)"
            }
        }
    }


    private func makeDecodeInitDeclWithSingleValueInitBody() throws -> InitializerDeclSyntax {
        guard let singleValueInitializer = findSingleValueInitializer() else {
            throw .diagnostic(node: declGroup.name, message: .codingMacro.singleValueCodable.missingSingleValueInitializer)
        }
        return try InitializerDeclSyntax("public required init(from decoder: any Decoder) throws") {
            """
            let codingValue = switch Self.singleValueCodingDefaultValue {
                case .value(let defaultValue):
                    (try? CodingValue(from: decoder)) ?? defaultValue
                case .none:
                    try CodingValue(from: decoder)
            }
            """
            singleValueInitializer.body?.statements.map(\.trimmed) ?? []
        }
    }


    private func makeEncodeFuncDecl() throws -> FunctionDeclSyntax {

        let overrideClause = (inherit ? "override " : "") as SyntaxNodeString

        return try FunctionDeclSyntax("public \(overrideClause)func encode(to encoder: any Encoder) throws") {
            "try self.singleValueEncode().encode(to: encoder)"
            if inherit {
                "try super.encode(to: encoder)"
            }
        }

    }


    private func findSingleValueInitializer() -> InitializerDeclSyntax? {
        
        return declGroup.initializers.first { initializer in

            guard initializer.signature.effectSpecifiers?.throwsClause != nil else { return false }
            guard initializer.signature.effectSpecifiers?.asyncSpecifier == nil else { return false }

            let parameters = initializer.signature.parameterClause.parameters

            guard parameters.count == 2 else { return false }

            let firstParam = parameters[parameters.index(at: 0)]
            let secondParam = parameters[parameters.index(at: 1)]

            guard firstParam.firstName.trimmed.text == "from" else { return false }
            guard firstParam.secondName?.trimmed.text == "codingValue" else { return false }

            guard secondParam.firstName.trimmed.text == "decoder" else { return false }
            guard secondParam.secondName == nil else { return false }

            return true

        }

    }

}



extension CodingMacroImplBase.ErrorGroup {
    static var singleValueCodable: SingleValueCodableMacro.Error.Type {
        SingleValueCodableMacro.Error.self
    }
}
