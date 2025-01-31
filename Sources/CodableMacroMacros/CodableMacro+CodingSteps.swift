//
//  CodableMacro+CodingSteps.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/1/30.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


extension CodableMacro {
    
    /// Information about the required parent container of a coding step
    struct ParentContainerInfo: Sendable, Equatable {
        let name: TokenSyntax
        let key: String
    }
    
    
    /// Coding step for a container
    struct ContainerStep: Sendable, Equatable {
        let name: TokenSyntax
        let keysDef: TokenSyntax
        let isRequired: Bool
    }
    
    
    /// Represent one step for encoding / decoding
    enum CodingStep: Equatable {
        case container(ContainerStep, parent: ParentContainerInfo?)
        case value(CodingFieldInfo, parent: ParentContainerInfo)
        case endOptionalContainer
    }
    
    
    
    static func buildCodingSteps(
        from structure: CodingStructure,
        context: some MacroExpansionContext,
        macroNode: AttributeSyntax
    ) throws(DiagnosticsError) -> (steps: [CodingStep], enumDeclList: [EnumDeclSpec]) {
        
        // the list of Codingkey enum needed
        var enumDeclList: [EnumDeclSpec] = []
        // the resulting coding steps
        var steps: [CodingStep] = []
        // a stack of container variable name
        // the stack top is the current container for coding any sub fields or containers
        var containerStack: [TokenSyntax] = []
        
        func dfs(_ structure: borrowing CodingStructure) throws(DiagnosticsError) {
            
            switch structure {
                    
                case let .root(children):
                    let newEnum = EnumDeclSpec(
                        name: context.makeUniqueName("root"),
                        cases: .init(children.keys)
                    )
                    enumDeclList.append(newEnum)
                    steps.append(.container(
                        .init(name: "root", keysDef: newEnum.name, isRequired: true),
                        parent: nil
                    ))
                    containerStack.append("root")
                    for (_, child) in children {
                        try dfs(child)
                    }
                    containerStack.removeLast()
                    
                case let .node(pathElement, children, required):
                    let newEnum = EnumDeclSpec(
                        name: context.makeUniqueName(pathElement),
                        cases: .init(children.keys)
                    )
                    enumDeclList.append(newEnum)
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: Error.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(newEnum.name)Container" as TokenSyntax
                    steps.append(.container(
                        .init(name: containerName, keysDef: newEnum.name, isRequired: required),
                        parent: .init(name: parentContainerName, key: "k\(pathElement)")
                    ))
                    containerStack.append(containerName)
                    for (_, child) in children {
                        try dfs(child)
                    }
                    if !required {
                        steps.append(.endOptionalContainer)
                    }
                    containerStack.removeLast()
                    
                case let .leaf(pathElement, field):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: Error.unexpectedEmptyContainerStack)
                    }
                    steps.append(.value(
                        field,
                        parent: .init(name: parentContainerName, key: "k\(pathElement)")
                    ))
                    
            }
            
        }
        
        try dfs(structure)
        
        return (steps, enumDeclList)
        
    }
    
}
