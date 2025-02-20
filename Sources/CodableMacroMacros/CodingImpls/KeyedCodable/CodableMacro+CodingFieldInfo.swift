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
    
    struct CodingFieldInfo: Sendable, Equatable {
        
        var propertyInfo: PropertyInfo
        var path: [String] = []
        var defaultValue: ExprSyntax? = nil
        var isIgnored: Bool = false
        var decodeTransform: DecodeTransformSpec? = nil
        var encodeTransform: [ExprSyntax]? = nil
        var validateExprs: [ExprSyntax] = []
        
        var isRequired: Bool { propertyInfo.isRequired && defaultValue == nil }
        
    }
    
    
    struct DecodeTransformSpec: Sendable, Equatable {
        var decodeSourceType: ExprSyntax
        var transformExprs: [ExprSyntax]
    }
    
    
    static func extractCodingFieldInfoList(from properties: [PropertyInfo])
    throws(DiagnosticsError) -> ([CodingFieldInfo], canAutoImplement: Bool) {
        
        let infoList = try properties
            .map(extractCodingFieldInfo(from:))
            .compactMap(\.self)
        
        let notIgnoredInfoList = infoList.filter { !$0.isIgnored }
        
        if notIgnoredInfoList.count < infoList.count {
            // there are some properties that are marked as ignored, cannot auto-implement
            return (notIgnoredInfoList, false)
        }
        
        if infoList.isEmpty {
            // an empty list means no customization, can auto-implement
            return (infoList, true)
        }
        
        guard
            infoList.contains(where: {
                $0.path.count > 1                                       // has custom path
                || $0.defaultValue != nil                               // has custom macro level default value
                || $0.path.first != $0.propertyInfo.name.trimmed.text   // has custom path
            })
        else {
            // if no stored properties has any of the characteristics above, can auto-implement
            return (infoList, true)
        }
        
        // found some forms of customization, cannot auto-implement
        return (infoList, false)
        
    }
    
    
    static func extractCodingFieldInfo(from property: PropertyInfo) throws(DiagnosticsError) -> CodingFieldInfo? {
        
        // Find and group all the decorator macros supported
        let attributes = property.attributes
            .reduce(into: [DecoratorMacros:[AttributeSyntax]]()) { result, attribute in
                guard let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text else { return }
                guard let decoratorMacro = DecoratorMacros(rawValue: name) else { return }
                result[decoratorMacro, default: []].append(attribute)
            }
        
        guard attributes[.codingIgnore, default: []].isEmpty else {
            // found `@CodingIgnore`
            return .init(propertyInfo: property, isIgnored: true)
        }
        
        // extract `path` and `defaultValue` from `@CodingField` macro
        guard
            let (path, defaultValue) = try CodingFieldMacro.processProperty(
                property,
                macroNodes: attributes[.codingField, default: []]
            )
        else { return nil }
        
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
        
        return .init(
            propertyInfo: property,
            path: path,
            defaultValue: defaultValue,
            decodeTransform: decodeTransformSpec,
            encodeTransform: encodeTransforms,
            validateExprs: validateExprs
        )
        
    }
    
}
