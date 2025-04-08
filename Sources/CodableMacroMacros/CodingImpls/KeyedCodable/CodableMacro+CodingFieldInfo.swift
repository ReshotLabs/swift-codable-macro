//
//  CodableMacro+Helpers.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/9.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



extension CodableMacro {

    enum RequriementStrategy {

        case always, allowMissing, allowMismatch, allowAll

        var allowMismatch: Bool { self == .allowAll || self == .allowMismatch }
        var allowMissing: Bool { self == .allowAll || self == .allowMissing }

        static func | (lhs: RequriementStrategy, rhs: RequriementStrategy) -> RequriementStrategy {
            switch (lhs, rhs) {
                case (.always, _): .always
                case (_, .always): .always
                case (.allowMissing, .allowMismatch): .always
                case (.allowMismatch, .allowMissing): .always
                case (.allowAll, let other): other
                case (let other, .allowAll): other
                case (let strategy, _): strategy
            }
        }
        
    }
    
    
    struct CodingFieldInfo: Sendable, Equatable {
        
        var propertyInfo: PropertyInfo
        var path: [String] = []
        var defaultValueOnMissing: ExprSyntax? = nil
        var defaultValueOnMisMatch: ExprSyntax? = nil
        var isIgnored: Bool = false
        var decodeTransform: DecodeTransformSpec? = nil
        var encodeTransform: [ExprSyntax]? = nil
        var validateExprs: [ExprSyntax] = []
        var sequenceCodingFieldInfo: SequenceCodingFieldInfo? = nil
        
        var requirementStrategy: RequriementStrategy {
            switch (propertyInfo.isRequired, defaultValueOnMisMatch, defaultValueOnMissing) {
                case (true, .none, .none): .always
                case (false, .none, .none): .allowAll
                case (_, .some, .none): .allowMismatch
                case (_, .none, .some): .allowMissing
                case (_, .some, .some): .allowAll
            }
        }
        
    }


    struct SequenceCodingFieldInfo: Sendable, Equatable, Hashable {

        var propertyName: TokenSyntax
        var path: [String]
        var elementEncodedType: ExprSyntax
        var defaultValueOnMissing: SequenceCodingFieldMacro.ErrorStrategy = .throwError
        var defaultValueOnMismatch: SequenceCodingFieldMacro.ErrorStrategy = .throwError
        var decodeTransformExpr: ExprSyntax? = nil 
        var encodeTransformExpr: ExprSyntax? = nil

        var requirementStrategy: RequriementStrategy {
            switch (defaultValueOnMissing, defaultValueOnMismatch) {
                case (.throwError, .throwError): .always
                case (.throwError, _): .allowMismatch
                case (_, .throwError): .allowMissing
                case (_, _): .allowAll
            }
        }

    }
    
    
    struct DecodeTransformSpec: Sendable, Equatable {
        var decodeSourceType: ExprSyntax
        var transformExprs: [ExprSyntax]
    }
    
    
    static func extractCodingFieldInfoList(from properties: [PropertyInfo])
    throws(DiagnosticsError) -> [CodingFieldInfo] {
        try properties
            .map(extractCodingFieldInfo(from:))
            .compactMap(\.self)
    }
    
    
    static func extractCodingFieldInfo(from property: PropertyInfo) throws(DiagnosticsError) -> CodingFieldInfo? {
        
        // Find and group all the decorator macros supported
        let attributes = property.attributes
            .reduce(into: [DecoratorMacros:[AttributeSyntax]]()) { result, attribute in
                guard let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text else { return }
                guard let decoratorMacro = DecoratorMacros(rawValue: name) else { return }
                result[decoratorMacro, default: []].append(attribute)
            }
        
        if let ignoreMacros = attributes[.codingIgnore], !ignoreMacros.isEmpty {
            // found `@CodingIgnore`
            try CodingIgnoreMacro.processProperty(property, macroNodes: ignoreMacros)
            return .init(propertyInfo: property, isIgnored: true)
        }
        
        // extract `path` and `defaultValue` from `@CodingField` macro
        let codingFieldSpec = try CodingFieldMacro.processProperty(
            property,
            macroNodes: attributes[.codingField, default: []]
        )
        
        let encodeTransformMacros = attributes[.encodeTransform, default: []]
        let decodeTransformMacros = attributes[.decodeTransform, default: []]
        let codingTransformMacros = attributes[.codingTransform, default: []]
        
        guard !((!encodeTransformMacros.isEmpty || !decodeTransformMacros.isEmpty) && !codingTransformMacros.isEmpty) else {
            // CodingTransform cannot be used together with EncodeTransform and DecodeTransform
            let allTransformMacros = encodeTransformMacros + decodeTransformMacros + codingTransformMacros
            let allTransformMacroStrs = allTransformMacros.map(\.attributeName.trimmedDescription)
            throw .diagnostics(
                allTransformMacros.map {
                    .init(node: $0, message: .decorator.general.conflictDecorators(allTransformMacroStrs))
                }
            )
        }
        
        // extract transformations
        let encodeTransforms: [ExprSyntax]?
        let decodeTransformSpec: DecodeTransformSpec?
        
        if let specs = try CodingTransformMacro.processProperty(
            property,
            macroNodes: codingTransformMacros
        ) {
            decodeTransformSpec = .init(decodeSourceType: specs.decodeSourceType, transformExprs: specs.decodeTransforms)
            encodeTransforms = specs.encodeTransforms
        } else {
            if let decodeSpec = try DecodeTransformMacro.processProperty(property, macroNodes: decodeTransformMacros) {
                decodeTransformSpec = .init(decodeSourceType: decodeSpec.decodeSourceType, transformExprs: [decodeSpec.transforms])
            } else {
                decodeTransformSpec = nil
            }
            if let encodeTransform = try EncodeTransformMacro.processProperty(property, macroNodes: encodeTransformMacros) {
                encodeTransforms = [encodeTransform]
            } else {
                encodeTransforms = nil
            }
        }
        
        // extract validations
        let validateExprs = try CodingValidateMacro.processProperty(
            property,
            macroNodes: attributes[.codingValidate, default: []]
        )

        // extract sequence coding 
        let codingSequenceFieldSpec = if let spec = try SequenceCodingFieldMacro.processProperty(
            property,
            macroNodes: attributes[.sequenceCodingField, default: []]
        ) {
            SequenceCodingFieldInfo(
                propertyName: property.name,
                path: spec.path, 
                elementEncodedType: spec.elementEncodedType, 
                defaultValueOnMissing: spec.defaultValueOnMissing, 
                defaultValueOnMismatch: spec.defaultValueOnMismatch, 
                decodeTransformExpr: spec.decodeTransformExpr,
                encodeTransformExpr: spec.encodeTransformExpr
            )
        } else {
            nil as SequenceCodingFieldInfo?
        }

        guard let codingFieldSpec else { return nil }
        
        return .init(
            propertyInfo: property,
            path: codingFieldSpec.path,
            defaultValueOnMissing: codingFieldSpec.defaultValueOnMissing,
            defaultValueOnMisMatch: codingFieldSpec.defaultValueOnMismatch,
            decodeTransform: decodeTransformSpec,
            encodeTransform: encodeTransforms,
            validateExprs: validateExprs,
            sequenceCodingFieldInfo: codingSequenceFieldSpec
        )
        
    }
    
}
