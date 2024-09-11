//
//  ArgumentsParsing.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/9.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation



extension AttributeListSyntax {
    
    func first(withName name: String) -> AttributeSyntax? {
        self.first {
            $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == name
        }?.as(AttributeSyntax.self)
    }
    
    
    func filter(byName predicate: (String) -> Bool) -> [AttributeSyntax] {
        self.compactMap {
            $0.as(AttributeSyntax.self)
        }.filter {
            predicate($0.attributeName.as(IdentifierTypeSyntax.self)?.name.text ?? $0.attributeName.trimmedDescription)
        }
    }
    
    
    func filter(byName name: String) -> [AttributeSyntax] {
        self.filter(byName: { $0 == name })
    }
    
    
    func grouped() -> [String:[AttributeSyntax]] {
        .init(
            grouping: self.compactMap({ $0.as(AttributeSyntax.self) }),
            by: { $0.attributeName.trimmedDescription }
        )
    }
    
}



extension LabeledExprListSyntax {
    
    func grouped() -> [String? : [LabeledExprSyntax]] {
        .init(grouping: self, by: { $0.label?.trimmed.text })
    }
    
    
    func grouped(
        with rules: [ArgumentsParsingRule]
    ) throws(DiagnosticsError) -> [[LabeledExprSyntax]] {
        
        guard !rules.isEmpty else { return [] }
        
        var result = [[LabeledExprSyntax]](repeating: [], count: rules.count)
        var parmIndex = 0
        
        for (ruleIndex, rule) in rules.enumerated() {
            
            guard parmIndex < self.count else {
                if rule.canIgnore { continue }
                throw .diagnostic(
                    node: self,
                    message: ArgumentsParsingRule.Error.notMatch(rule: rule, argumentIndex: parmIndex)
                )
            }
            
            let param = self[self.index(at: parmIndex)]
            
            guard rule.label == param.label?.trimmed.text else {
                if rule.canIgnore { continue }
                throw .diagnostic(
                    node: self,
                    message: ArgumentsParsingRule.Error.notMatch(rule: rule, argumentIndex: parmIndex)
                )
            }
            
            result[ruleIndex].append(param)
            parmIndex += 1
            
            guard rule.isVarArg else { continue }
            
            let additionalVarArgs = self.dropFirst(parmIndex).prefix(while: { $0.label == nil })
            result[ruleIndex].append(contentsOf: additionalVarArgs)
            parmIndex += additionalVarArgs.count
            
        }
        
        guard parmIndex == self.count else {
            throw.diagnostic(
                node: self,
                message: ArgumentsParsingRule.Error.extraArguments(index: parmIndex)
            )
        }
        
        return result
        
    }
    
}



extension AttributeSyntax.Arguments {
    
    func grouped() -> [String? : [LabeledExprSyntax]] {
        self.as(LabeledExprListSyntax.self)?.grouped() ?? [:]
    }
    
    func grouped(
        with rules: [ArgumentsParsingRule]
    ) throws(DiagnosticsError) -> [[LabeledExprSyntax]] {
        guard let parameterList = self.as(LabeledExprListSyntax.self) else { return [] }
        return try parameterList.grouped(with: rules)
    }
    
}



struct ArgumentsParsingRule {
    let label: String?
    let isVarArg: Bool
    let canIgnore: Bool
    init(label: String? = nil, isVarArg: Bool = false, canIgnore: Bool = false) {
        self.label = label
        self.isVarArg = isVarArg
        self.canIgnore = canIgnore
    }
    static func labeledVarArg(_ label: String, canIgnore: Bool = false) -> Self {
        .init(label: label, isVarArg: true, canIgnore: canIgnore)
    }
    static func varArg(canIgnore: Bool = false) -> Self {
        .init(isVarArg: true, canIgnore: canIgnore)
    }
    static func normal(canIgnore: Bool = false) -> Self {
        .init(canIgnore: canIgnore)
    }
    static func labeled(_ label: String, canIgnore: Bool = false) -> Self {
        .init(label: label, canIgnore: canIgnore)
    }
}


extension ArgumentsParsingRule {
    
    enum Error: LocalizedError, DiagnosticMessage {
        
        case notMatch(rule: ArgumentsParsingRule, argumentIndex: Int)
        case extraArguments(index: Int)
        
        var errorDescription: String? { message }
        
        var diagnosticID: MessageID {
            switch self {
                case .notMatch: .init(domain: "ParameterListParsingError", id: "NotMatch")
                case .extraArguments: .init(domain: "ParameterListParsingError", id: "ExtraArguments")
            }
        }
        
        var severity: DiagnosticSeverity { .error }
        
        var message: String {
            switch self {
                case let .notMatch(rule, argumentIndex):
                    "expect \(rule.label == nil ? "labelled " : "")\(rule.isVarArg ? "vararg" : "argument") at index \(argumentIndex)"
                case let .extraArguments(index):
                    "unexpected extra arguments after index \(index)"
            }
        }
        
    }
    
}

