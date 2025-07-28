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
    
    
    struct PropertyCodingSpec: Sendable, Equatable {
        
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
    
}



extension CodableMacro {

    func extractPropertyCodingSpecList() throws(DiagnosticsError) -> [PropertyCodingSpec] {
        try declGroup.properties
            .map(extractPropertyCodingSpec(from:))
            .getResults()
            .filter { $0.propertyInfo.type != .computed }
    }


    private func extractCodingFieldSpec(
        from codingFieldDecorators: [AttributeSyntax],
        onTarget property: PropertyInfo
    ) -> DiagnosticResult<(path: [String], defaultValueOnMissing: ExprSyntax?, defaultValueOnMismatch: ExprSyntax?)> {
        captureDiagnostics { () throws(DiagnosticsError) in
            if codingFieldDecorators.isNotEmpty, property.type == .computed {
                throw .diagnostics(codingFieldDecorators.map { .init(node: $0, message: .codingMacro.codable.codingCustomizationOnNonStoredProperty) })
            }
            let codingFieldSetting = try CodingFieldMacro.extractSetting(from: codingFieldDecorators, in: context)
            if 
                let defaultValue = codingFieldSetting?.defaultValueOnMissing ?? codingFieldSetting?.defaultValueOnMismatch, 
                property.initializer != nil,
                property.type == .constant 
            {
                throw .diagnostic(node: defaultValue, message: .codingMacro.codable.defaultValueOnConstantwithInitializer)
            }
            return codingFieldSetting
                .map { path, onMissing, onMismatch in
                    let finalPath = path ?? [self.transformPropertyName(property.nameStr)]
                    return (path: finalPath, defaultValueOnMissing: onMissing, defaultValueOnMismatch: onMismatch)
                }
                .orElse {
                    (path: [self.transformPropertyName(property.nameStr)], defaultValueOnMissing: nil, defaultValueOnMismatch: nil)
                }
        }
    }


    private func extractCodingTransformSpec(
        encodeTransformDecorators: [AttributeSyntax],
        decodeTransformDecorators: [AttributeSyntax],
        codingTransformDecorators: [AttributeSyntax],
        onTarget property: PropertyInfo
    ) -> DiagnosticResult<(encodeTransforms: [ExprSyntax]?, decodeTransformSpec: DecodeTransformSpec?)> {

        captureDiagnostics { () throws(DiagnosticsError) in

            var targetDiagnostics: [Diagnostic] = []

            if encodeTransformDecorators.isNotEmpty, property.type == .computed {
                targetDiagnostics.append(contentsOf:
                    encodeTransformDecorators.map { .init(node: $0, message: .codingMacro.codable.codingCustomizationOnNonStoredProperty) }
                )
            }
            if decodeTransformDecorators.isNotEmpty, property.type == .computed {
                targetDiagnostics.append(contentsOf: 
                    decodeTransformDecorators.map { .init(node: $0, message: .codingMacro.codable.codingCustomizationOnNonStoredProperty) }
                )
            }
            if codingTransformDecorators.isNotEmpty, property.type == .computed {
                targetDiagnostics.append(contentsOf: 
                    codingTransformDecorators.map { .init(node: $0, message: .codingMacro.codable.codingCustomizationOnNonStoredProperty) }
                )
            }

            guard targetDiagnostics.isEmpty else {
                throw .diagnostics(targetDiagnostics)
            }

            if codingTransformDecorators.isNotEmpty {
                var diagnostics: [Diagnostic] = []
                if encodeTransformDecorators.isNotEmpty {
                    diagnostics.append(contentsOf: codingTransformDecorators.map { 
                        .init(node: $0, message: .codingMacro.general.conflictDecorators(.codingTransform, .encodeTransform)) 
                    })
                    diagnostics.append(contentsOf: encodeTransformDecorators.map { 
                        .init(node: $0, message: .codingMacro.general.conflictDecorators(.codingTransform, .encodeTransform)) 
                    })
                }
                if decodeTransformDecorators.isNotEmpty {
                    diagnostics.append(contentsOf: codingTransformDecorators.map { 
                        .init(node: $0, message: .codingMacro.general.conflictDecorators(.codingTransform, .decodeTransform)) 
                    })
                    diagnostics.append(contentsOf: decodeTransformDecorators.map { 
                        .init(node: $0, message: .codingMacro.general.conflictDecorators(.codingTransform, .decodeTransform)) 
                    })
                }
                if !diagnostics.isEmpty {
                    throw .diagnostics(diagnostics)
                }
            }
            
            // extract transformations
            let encodeTransforms: [ExprSyntax]?
            let decodeTransformSpec: DecodeTransformSpec?
            
            if let settings = try CodingTransformMacro.extractSetting(from: codingTransformDecorators, in: context) {
                decodeTransformSpec = .init(decodeSourceType: settings.decodeSourceType, transformExprs: settings.decodeTransforms)
                encodeTransforms = settings.encodeTransforms
            } else {
                if let decodeSetting = try DecodeTransformMacro.extractSetting(from: decodeTransformDecorators, in: context) {
                    decodeTransformSpec = .init(decodeSourceType: decodeSetting.decodeSourceType, transformExprs: [decodeSetting.transforms])
                } else {
                    decodeTransformSpec = nil
                }
                if let encodeTransformSetting = try EncodeTransformMacro.extractSetting(from: encodeTransformDecorators, in: context) {
                    encodeTransforms = [encodeTransformSetting]
                } else {
                    encodeTransforms = nil
                }
            }

            return (encodeTransforms, decodeTransformSpec)

        }

    }


    private func extractCodingValidationSpec(from codingValidateDecorators: [AttributeSyntax]) -> DiagnosticResult<[ExprSyntax]> {
        captureDiagnostics { () throws(DiagnosticsError) in
            if codingValidateDecorators.isNotEmpty, declGroup.properties.contains(where: { $0.type == .computed }) {
                throw .diagnostics(codingValidateDecorators.map { .init(node: $0, message: .codingMacro.codable.codingCustomizationOnNonStoredProperty) })
            }
            return try CodingValidateMacro.extractSetting(from: codingValidateDecorators, in: context)
        }
    }


    private func extractSequenceCodingFieldSpec(
        from sequenceCodingFieldDecorators: [AttributeSyntax],
        onTarget property: PropertyInfo
    ) -> DiagnosticResult<SequenceCodingFieldInfo?> {
        captureDiagnostics { () throws(DiagnosticsError) in
            if sequenceCodingFieldDecorators.isNotEmpty, declGroup.properties.contains(where: { $0.type == .computed }) {
                throw .diagnostics(sequenceCodingFieldDecorators.map { 
                    .init(node: $0, message: .codingMacro.codable.codingCustomizationOnNonStoredProperty) 
                })
            }
            return try SequenceCodingFieldMacro.extractSetting(from: sequenceCodingFieldDecorators, in: context)
                .map {
                    .init(
                        propertyName: property.name,
                        path: $0.path,
                        elementEncodedType: $0.elementEncodedType,
                        defaultValueOnMissing: $0.defaultValueOnMissing,
                        defaultValueOnMismatch: $0.defaultValueOnMismatch,
                        decodeTransformExpr: $0.decodeTransformExpr,
                        encodeTransformExpr: $0.encodeTransformExpr
                    )
                }
        }
    }
    
    
    private func extractPropertyCodingSpec(from property: PropertyInfo) -> DiagnosticResult<PropertyCodingSpec> {
        
        // Find and group all the decorator macros supported
        let attributes = gatherSupportedDecorators(in: property.attributes)
        
        if let ignoreMacros = attributes[.codingIgnore], let ignoreMacro = ignoreMacros.first {
            // found `@CodingIgnore`
            guard property.type != .computed else {
                return .failure(.diagnostic(node: property.name, message: .codingMacro.codable.codingCustomizationOnNonStoredProperty))
            }
            guard property.initializer != nil || property.hasOptionalTypeDecl else {
                return .failure(.diagnostic(node: ignoreMacro, message: .codingMacro.codable.propertyCannotBeIgnored))
            }
            return .success(.init(propertyInfo: property, isIgnored: true))
        }
        
        // extract `path` and `defaultValue` from `@CodingField` macro
        let codingFieldSpec = extractCodingFieldSpec(from: attributes[.codingField, default: []], onTarget: property)
        
        // extract transformations
        let codingTransformSpec = extractCodingTransformSpec(
            encodeTransformDecorators: attributes[.encodeTransform, default: []], 
            decodeTransformDecorators: attributes[.decodeTransform, default: []], 
            codingTransformDecorators: attributes[.codingTransform, default: []], 
            onTarget: property
        )
        
        // extract validations
        let validateExprs = extractCodingValidationSpec(from: attributes[.codingValidate, default: []])

        // extract sequence coding 
        let codingSequenceFieldSpec = extractSequenceCodingFieldSpec(
            from: attributes[.sequenceCodingField, default: []], 
            onTarget: property
        )

        return mapDiagnosticResults(
            codingFieldSpec, 
            codingTransformSpec, 
            validateExprs, 
            codingSequenceFieldSpec
        ) { codingFieldSpec, codingTransformSpec, validateExprs, codingSequenceFieldSpec in
            .init(
                propertyInfo: property,
                path: codingFieldSpec.path,
                defaultValueOnMissing: codingFieldSpec.defaultValueOnMissing,
                defaultValueOnMisMatch: codingFieldSpec.defaultValueOnMismatch,
                decodeTransform: codingTransformSpec.decodeTransformSpec,
                encodeTransform: codingTransformSpec.encodeTransforms,
                validateExprs: validateExprs,
                sequenceCodingFieldInfo: codingSequenceFieldSpec
            )
        }
        
    }

}
