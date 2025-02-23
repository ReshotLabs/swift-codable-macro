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
        
        let containerCodingKeysPrefix = "$__coding_container_keys_" as TokenSyntax
        let containerVarNamePrefix = "$__coding_container_" as TokenSyntax
        
        func dfs(_ structure: borrowing CodingStructure) throws(DiagnosticsError) {
            
            switch structure {
                    
                case let .root(children):
                    let containerName = "root" as TokenSyntax
                    let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax
                    let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
                    enumDeclList.append(
                        .init(name: containerCodingKeysName, cases: .init(children.keys))
                    )
                    steps.append(.container(
                        .init(name: containerVarName, keysDef: containerCodingKeysName, isRequired: true),
                        parent: nil
                    ))
                    containerStack.append(containerName)
                    for (_, child) in children {
                        try dfs(child)
                    }
                    containerStack.removeLast()
                    
                case let .node(pathElement, children, required):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    let containerCodingKeysName = "\(containerCodingKeysPrefix)\(containerName)" as TokenSyntax
                    let containerVarName = "\(containerVarNamePrefix)\(containerName)" as TokenSyntax
                    enumDeclList.append(
                        .init(name: containerCodingKeysName, cases: .init(children.keys))
                    )
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    steps.append(.container(
                        .init(name: containerVarName, keysDef: containerCodingKeysName, isRequired: required),
                        parent: .init(name: parentContainerVarName, key: "k\(pathElement)")
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
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let parentContainerVarName = "\(containerVarNamePrefix)\(parentContainerName)" as TokenSyntax
                    steps.append(.value(
                        field,
                        parent: .init(name: parentContainerVarName, key: "k\(pathElement)")
                    ))
                    
            }
            
        }
        
        try dfs(structure)
        
        return (steps, enumDeclList)
        
    }
    
}
