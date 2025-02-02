//
//  PropertyInfo.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/1/28.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation



struct PropertyInfo: Sendable, Equatable {
    
    var name: TokenSyntax
    var type: PropertyType
    var initializer: ExprSyntax?
    var dataType: TypeSyntax?
    var attributes: [AttributeSyntax]
    
    var hasOptionalTypeDecl: Bool { dataType?.is(OptionalTypeSyntax.self) == true }
    var nameStr: String { name.text }
    var isRequired: Bool { initializer == nil && !hasOptionalTypeDecl }
    var typeExpression: ExprSyntax? {
        if let dataType {
            "\(dataType).self"
        } else if let initializer {
            "CodableMacro.codableMacroStaticType(of: \(initializer))"
        } else {
            nil
        }
    }
    
}



extension PropertyInfo {
    
    enum PropertyType: Sendable, Equatable, Hashable {
        case constant
        case stored
        case computed
    }
    
}



extension PropertyInfo {
    
    static func extract(from declaration: VariableDeclSyntax) throws(DiagnosticsError) -> PropertyInfo {
        
        let attributes = declaration.attributes.compactMap { $0.as(AttributeSyntax.self) }
        
        guard let name = declaration.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw .diagnostic(node: declaration, message: Error.missingIdentifier)
        }
        
        let initializer = declaration.bindings.first?.initializer?.value
        
        let typeAnnotation = declaration.bindings.first?.typeAnnotation?.type.trimmed
        
        let type: PropertyType
        
        if declaration.bindingSpecifier.tokenKind == .keyword(.let) {
            type = .constant
        } else if initializer != nil {
            type = .stored
        } else if let accessors = declaration.bindings.first?.accessorBlock?.accessors {
            if let accessors = accessors.as(AccessorDeclListSyntax.self) {
                let isComputed = accessors.isEmpty || accessors.lazy
                    .map { $0.accessorSpecifier.tokenKind }
                    .contains { $0 == .keyword(.get) || $0 == .keyword(.set) }
                type = isComputed ? .computed : .stored
            } else {
                type = .computed
            }
        } else {
            type = .stored
        }
        
        return .init(
            name: name,
            type: type,
            initializer: initializer,
            dataType: typeAnnotation,
            attributes: attributes
        )
        
    }
    
    
    enum Error: String, LocalizedError, DiagnosticMessage {
        case missingIdentifier = "missing_identifier"
        var diagnosticID: MessageID {
            .init(domain: "com.serika.codable_macro.property_info", id: self.rawValue)
        }
        var severity: DiagnosticSeverity { .error }
        var message: String {
            switch self {
                case .missingIdentifier: "Missing identifier for property"
            }
        }
    }
    
}
