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
    static let supportedDecorators: Set<DecoratorMacros> = [.singleValueCodableDelegate]

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
    
    
    func makeConformingProtocols() throws -> [TypeSyntax] {
        if inherit {
            ["InheritedSingleValueCodableProtocol"]
        } else {
            ["SingleValueCodableProtocol"]
        }
    }
    
    
    func makeDecls() throws -> [DeclSyntax] {
        
        let delegateProperties = try declGroup.properties
            .compactMap { propertyInfo in
                let delegateAttributes = gatherSupportedDecorators(in: propertyInfo.attributes)[.singleValueCodableDelegate, default: []]
                guard !delegateAttributes.isEmpty else { return nil as DiagnosticResult<(PropertyInfo, ExprSyntax?)>? }
                return captureDiagnostics { () throws(DiagnosticsError) in
                    guard propertyInfo.type != .computed else {
                        throw .diagnostic(node: propertyInfo.name, message: .codingMacro.singleValueCodable.delegateDecoratorOnNonStoredProperty)
                    }
                    let defaultValue = try SingleValueCodableDelegateMacro.extractSetting(from: delegateAttributes, in: context)
                    return (propertyInfo, defaultValue)
                }
            }
            .getResults() as [(PropertyInfo, ExprSyntax?)]
        
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

        static let delegateDecoratorOnNonStoredProperty: CodingMacroImplBase.Error = .init(
            id: "delegate_decorator_on_non_stored_property",
            message: "SingleValueCodableDelegate can only be attached to stored properties"
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



extension CodingMacroImplBase.ErrorGroup {
    static var singleValueCodable: SingleValueCodableMacro.Error.Type {
        SingleValueCodableMacro.Error.self
    }
}
