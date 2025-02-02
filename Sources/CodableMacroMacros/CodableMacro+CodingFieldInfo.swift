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
        var decodeTransform: DecodeTransformMacro.Spec? = nil
        
        var isRequired: Bool { propertyInfo.isRequired && defaultValue == nil }
        
    }
    
    
    static func extractCodingFieldInfoList(from members: MemberBlockItemListSyntax)
    throws(DiagnosticsError) -> ([CodingFieldInfo], canAutoImplement: Bool) {
        
        let infoList = try members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .map(PropertyInfo.extract(from:))
            .filter { $0.type != .computed }
            .map(extractCodingFieldInfo(from:))
        
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
    
    
    static func extractCodingFieldInfo(from property: PropertyInfo) throws(DiagnosticsError) -> CodingFieldInfo {
        
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
        let (path, defaultValue) = try { () throws(DiagnosticsError) in
            
            let codingFieldMacroList = attributes[.codingField]
            
            guard (codingFieldMacroList?.count ?? 0) < 2 else {
                // There should not be multiple `@CodingField` macro on one property
                throw .diagnostic(node: property.name, message: Error.multipleCodingField)
            }
            
            return if let codingFieldMacro = codingFieldMacroList?.first {
                // case when there is a `@CodingField` macro
                try CodingFieldMacro.processCodingField(property, macroNode: codingFieldMacro)
            } else {
                // case when there is no `@CodingField` macro
                ([property.name.trimmed.text], nil)
            }
            
        }()
        
        let decodeTransformSpec = try DecodeTransformMacro.processProperty(
            property,
            macroNodes: attributes[.decodeTransform, default: []]
        )
        
        return .init(
            propertyInfo: property,
            path: path,
            defaultValue: defaultValue,
            decodeTransform: decodeTransformSpec
        )
        
    }
    
}
