import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



extension CodableMacro {

    private static func generateSingleEnumDeclaration<Cases: Collection>(
        name: TokenSyntax, 
        cases: Cases
    ) -> DeclSyntax 
    where Cases.Element == String {
        """
        enum \(name): String, CodingKey {
            case \(raw: cases.map { #"k\#($0) = "\#($0)""# }.joined(separator: ","))
        }
        """
    }


    static func generateEnumDeclarations(from structure: CodingStructure, macroNode: AttributeSyntax) throws -> [DeclSyntax] {

        let enumNamePrefix = "$__coding_container_keys_" as TokenSyntax

        var containerStack: [TokenSyntax] = []
        var enumDecls = [DeclSyntax]() 


        func dfs(_ structure: CodingStructure) throws {

            switch structure {

                case let .root(children, _):
                    let containerName = "root" as TokenSyntax
                    enumDecls.append(
                        generateSingleEnumDeclaration(name: "\(enumNamePrefix)\(containerName)", cases: children.keys)
                    )
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    for child in children.values {
                        try dfs(child)
                    }

                case let .node(pathElement, children, _):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    enumDecls.append(
                        generateSingleEnumDeclaration(name: "\(enumNamePrefix)\(containerName)", cases: children.keys)
                    )
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    for child in children.values {
                        try dfs(child)
                    }

                case let .sequenceLeaf(pathElement, _, subTree):
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    try dfs(subTree)

                case .leaf: break 

            }

        }

        func dfs(_ structure: SequenceCodingSubStructure) throws {

            switch structure {
                case let .root(children, _): do {
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: "root")" as TokenSyntax
                    enumDecls.append(
                        generateSingleEnumDeclaration(name: "\(enumNamePrefix)\(containerName)", cases: children.keys)
                    )
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    for child in children.values {
                        try dfs(child)
                    }
                }
                case let .node(pathElement, children, _): do {
                    guard let parentContainerName = containerStack.last else {
                        throw .diagnostic(node: macroNode, message: .codingMacro.codable.unexpectedEmptyContainerStack)
                    }
                    let containerName = "\(parentContainerName)_\(raw: pathElement)" as TokenSyntax
                    enumDecls.append(
                        generateSingleEnumDeclaration(name: "\(enumNamePrefix)\(containerName)", cases: children.keys)
                    )
                    containerStack.append(containerName)
                    defer { containerStack.removeLast() }
                    for child in children.values {
                        try dfs(child)
                    }
                }
                case .leaf: break
            }

        }

        try dfs(structure)

        return enumDecls

    }

}