//
//  CodingStructure.swift
//  CodableMacro
//
//  Created by Star_Lord_PHB on 2024/9/7.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import OrderedCollections


infix operator ==== : ComparisonPrecedence


/// Represent the Encoding / Decoding structure as a tree
indirect enum CodingStructure: Hashable, Equatable {
    
    case root(children: OrderedDictionary<String, CodingStructure>)
    case node(pathElement: String, children: OrderedDictionary<String, CodingStructure>, required: Bool)
    case leaf(pathElement: String, field: CodableMacro.CodingFieldInfo)
    
    var pathElement: String? {
        switch self {
            case .root: nil
            case let .node(pathElement, _, _): pathElement
            case let .leaf(pathElement, _): pathElement
        }
    }
    
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.pathElement == rhs.pathElement
    }
    
    
    static func ==== (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case let (.root(childrenL), .root(childrenR)):
                guard childrenL.count == childrenR.count else { return false }
                return childrenL.allSatisfy { (pathElement, childL) in
                    guard
                        let childR = childrenR[pathElement]
                    else { return false }
                    return childL ==== childR
                }
            case let (.node(pathElementL, childrenL, requiredL), .node(pathElementR, childrenR, requiredR)):
                guard
                    pathElementL == pathElementR,
                    childrenL.count == childrenR.count,
                    requiredL == requiredR
                else { return false }
                return childrenL.allSatisfy { (pathElement, childL) in
                    guard
                        let childR = childrenR[pathElement]
                    else { return false }
                    return childL ==== childR
                }
            case let (.leaf(pathElementL, fieldL), .leaf(pathElementR, fieldR)):
                return pathElementL == pathElementR && fieldL.propertyInfo.nameStr == fieldR.propertyInfo.nameStr
            default:
                return false
        }
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.pathElement)
    }
    
}


extension CodingStructure: CustomStringConvertible {
    
    private func dfsAllPaths(of structure: CodingStructure, paths: inout [[String]]) {
        switch structure {
            case let .root(children):
                for child in children.values {
                    paths.append([])
                    dfsAllPaths(of: child, paths: &paths)
                }
            case let .node(pathElement, children, _):
                let path = paths[paths.endIndex - 1] + [pathElement.description]
                paths[paths.endIndex - 1].append(pathElement.description)
                for child in children.values {
                    dfsAllPaths(of: child, paths: &paths)
                    paths.append(path)
                }
                paths.removeLast()
            case let .leaf(pathElement, _):
                paths[paths.endIndex - 1].append(pathElement.description)
        }
    }
    
    var description: String {
        var allPaths = [[String]]()
        let structure = if case .root(_) = self {
            self
        } else {
            CodingStructure.root(children: [pathElement!: self])
        }
        dfsAllPaths(of: structure, paths: &allPaths)
        return allPaths
            .map { $0.description }
            .joined(separator: "\n")
    }
    
}



extension CodingStructure {
    
    static func parse(_ codingFieldInfoList: [CodableMacro.CodingFieldInfo]) throws(DiagnosticsError) -> CodingStructure {
        
        var root = CodingStructure.root(children: [:])
        
        for codingFieldInfo in codingFieldInfoList {
            try matchAndUpdate(&root, with: codingFieldInfo.path, field: codingFieldInfo)
        }
        
        return root
        
    }
    
    
    private static func matchAndUpdate<Path: Collection<String>>(
        _ structure: inout CodingStructure,
        with path: Path,
        field: CodableMacro.CodingFieldInfo
    ) throws (DiagnosticsError) {
        
        let isLeaf = (path.count == 1)
        guard let pathElementToMatch = path.first else { return }
        
        switch structure {
                
            case let .leaf(_, conflictField):
                // should never see a leaf when matching the path of a new property
                // seeing a leaf means that a path conflict exist
                throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyInfo.name, property2: conflictField.propertyInfo.name))
                
            case var .root(children):
                guard children[pathElementToMatch] != nil else {
                    // no match found
                    if isLeaf {
                        children[pathElementToMatch] = .leaf(pathElement: pathElementToMatch, field: field)
                        structure = .root(children: children)
                    } else {
                        var newNode = CodingStructure.node(pathElement: pathElementToMatch, children: [:], required: field.isRequired)
                        try matchAndUpdate(&newNode, with: path.dropFirst(), field: field)
                        children[pathElementToMatch] = newNode
                        structure = .root(children: children)
                    }
                    break
                }
                guard !isLeaf else {
                    // found a match, but it is the last component of the path of the new property
                    // in this case, it should be a path conflict of some unknown internal error
                    guard
                        let conflictStructure = children[pathElementToMatch],
                        let field2 = firstLeaf(in: conflictStructure)?.field.propertyInfo.name
                    else {
                        throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown)
                    }
                    throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyInfo.name, property2: field2))
                }
                try matchAndUpdate(&children[pathElementToMatch]!, with: path.dropFirst(), field: field)
                structure = .root(children: children)
                
            case .node(let pathElement, var children, let required):
                guard children[pathElementToMatch] != nil else {
                    // no match found
                    if isLeaf {
                        children[pathElementToMatch] = .leaf(pathElement: pathElementToMatch, field: field)
                        structure = .node(pathElement: pathElement, children: children, required: required || field.isRequired)
                    } else {
                        var newNode = CodingStructure.node(pathElement: pathElementToMatch, children: [:], required: required || field.isRequired)
                        try matchAndUpdate(&newNode, with: path.dropFirst(), field: field)
                        children[pathElementToMatch] = newNode
                        structure = .node(pathElement: pathElement, children: children, required: required || field.isRequired)
                    }
                    break
                }
                guard !isLeaf else {
                    // found a match, but it is the last component of the path of the new property
                    // in this case, it should be a path conflict of some unknown internal error
                    guard
                        let conflictStructure = children[pathElementToMatch],
                        let field2 = firstLeaf(in: conflictStructure)?.field.propertyInfo.name
                    else {
                        throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown)
                    }
                    throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyInfo.name, property2: field2))
                }
                try matchAndUpdate(&children[pathElementToMatch]!, with: path.dropFirst(), field: field)
                structure = .node(pathElement: pathElement, children: children, required: required || field.isRequired)
                
        }
        
    }
    
    
    static func firstLeaf(
        in structure: CodingStructure
    ) -> (pathElement: String, field: CodableMacro.CodingFieldInfo)? {
        switch structure {
            case let .root(children):
                for child in children.values {
                    guard let first = firstLeaf(in: child) else { continue }
                    return first
                }
            case let .node(_, children, _):
                for child in children.values {
                    guard let first = firstLeaf(in: child) else { continue }
                    return first
                }
            case let .leaf(pathElement, field):
                return (pathElement, field)
        }
        return nil
    }
    
    
    static func makePathConflictDiagnostics(
        property1: TokenSyntax,
        property2: TokenSyntax
    ) -> [Diagnostic] {
        [
            .init(
                node: property1,
                message: .codingMacro.codingStructureParsing.pathConflict,
                notes: [
                    .init(
                        node: .init(property1),
                        position: property1.position,
                        message: .string("""
                            Any two properties in the same type must not have the same coding path \
                            or having path that is a prefix of the the path of the other
                            """
                        )
                    ),
                    .init(
                        node: .init(property2),
                        position: property2.position,
                        message: .string(
                            "conflicted with the path of property \"\(property2.trimmed.text)\""
                        )
                    ),
                ]
            ),
            .init(
                node: property2,
                message: .codingMacro.codingStructureParsing.pathConflictDestination(source: property1)
            )
        ]
    }
    
    
    enum CodingStructureParsingError {
        
        static let pathConflict: CodingMacroDiagnosticMessage = .init(
            id: "path_conflict",
            message: "Property has path that conflict with that of another property"
        )
        
        static func pathConflictDestination(source: TokenSyntax) -> CodingMacroDiagnosticMessage {
            .init(
                id: "path_conflict_destination",
                message: "path of \"\(source.trimmed.text)\" conflicts with path of this property"
            )
        }
        
        static let unknown: CodingMacroDiagnosticMessage = .init(
            id: "unknown",
            message: "Internal Error: Unknown"
        )
        
    }
    
}



extension CodingMacroDiagnosticMessageGroup {
    static var codingStructureParsing: CodingStructure.CodingStructureParsingError.Type {
        CodingStructure.CodingStructureParsingError.self
    }
}
