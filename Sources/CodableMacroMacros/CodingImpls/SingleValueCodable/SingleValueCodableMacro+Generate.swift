import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics



extension SingleValueCodableMacro {

    func makeDeclsWithoutDelegateProperty() throws -> [DeclSyntax] {

        if inherit {
            return try buildDeclSyntaxList {
                try makeDecodeInitDeclWithSingleValueInitBody()
                try makeEncodeFuncDecl()
            }
        } else {
            return []
        }

    }


    func makeDeclsWithDelegateProperty(
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
            public static var singleValueCodingDefaultValue: CodingDefaultValue<\(codingValueType)> {
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