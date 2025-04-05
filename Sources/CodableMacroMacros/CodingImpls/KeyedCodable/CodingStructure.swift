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
    
    case root(children: OrderedDictionary<String, CodingStructure>, requirementStrategy: CodableMacro.RequriementStrategy)
    case node(pathElement: String, children: OrderedDictionary<String, CodingStructure>, requirementStrategy: CodableMacro.RequriementStrategy)
    case leaf(pathElement: String, field: CodableMacro.CodingFieldInfo)
    case sequenceLeaf(pathElement: String, fields: [CodableMacro.CodingFieldInfo], subTree: CodingSequenceSubStructure)
    
    var pathElement: String? {
        switch self {
            case .root: nil
            case let .node(pathElement, _, _): pathElement
            case let .leaf(pathElement, _): pathElement
            case let .sequenceLeaf(pathElement, _, _): pathElement
        }
    }
    
    
    var requirementStrategy: CodableMacro.RequriementStrategy {
        switch self {
            case let .root(_, strategy): strategy
            case let .node(_, _, strategy): strategy
            case let .leaf(_, field): field.requirementStrategy
            case let .sequenceLeaf(_, fields, _): fields.reduce(.allowAll) { $0 | $1.requirementStrategy }
        }
    }
    
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.pathElement == rhs.pathElement
    }
    
    
    static func ==== (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case let (.root(childrenL, _), .root(childrenR, _)):
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
                    guard let childR = childrenR[pathElement] else { return false }
                    return childL ==== childR
                }
            case let (.leaf(pathElementL, fieldL), .leaf(pathElementR, fieldR)):
                return pathElementL == pathElementR && fieldL.propertyInfo.nameStr == fieldR.propertyInfo.nameStr
            case let (.sequenceLeaf(pathElementL, fieldL, subTreeL), .sequenceLeaf(pathElementR, fieldR, subTreeR)):
                return pathElementL == pathElementR 
                       && fieldL == fieldR
                       && subTreeL ==== subTreeR
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
            case let .root(children, _):
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
            case let .sequenceLeaf(pathElement, _, _):
                paths[paths.endIndex - 1].append(pathElement.description)
        }
    }
    
    var description: String {
        var allPaths = [[String]]()
        let structure = if case .root = self {
            self
        } else {
            CodingStructure.root(children: [pathElement!: self], requirementStrategy: self.requirementStrategy)
        }
        dfsAllPaths(of: structure, paths: &allPaths)
        return allPaths
            .map { $0.description }
            .joined(separator: "\n")
    }
    
}



extension CodingStructure {
    
    static func parse(_ codingFieldInfoList: [CodableMacro.CodingFieldInfo]) throws(DiagnosticsError) -> CodingStructure {
        
        var root = CodingStructure.root(children: [:], requirementStrategy: .allowAll)
        
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
        
        switch structure {
                
            case let .leaf(_, conflictField):
                // should never see a leaf when matching the path of a new property
                // seeing a leaf means that a path conflict exist
                throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyInfo.name, property2: conflictField.propertyInfo.name))

            case .sequenceLeaf(let pathElement, var fields, var subTree as CodingSequenceSubStructure?): do {
                guard path.count == 0, let sequenceElementCodingFieldInfo = field.sequenceElementCodingFieldInfo else {
                    if let firstConflictField = fields.first?.propertyInfo.name {
                        throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyInfo.name, property2: firstConflictField))
                    } else {
                        throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown)
                    }
                }
                try CodingSequenceSubStructure.matchAndUpdateSequenceSubStructure(
                    &subTree, 
                    field: sequenceElementCodingFieldInfo, 
                    fieldName: field.propertyInfo.name
                )
                guard let subTree else { 
                    throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown) 
                }
                fields.append(field)
                structure = .sequenceLeaf(pathElement: pathElement, fields: fields, subTree: subTree)
            }
            
            case .root(var children, let requirementStrategy): do {
                guard let pathElementToMatch = path.first else {
                    guard let conflictedField = firstLeaf(in: structure) else {
                        throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown)
                    }
                    throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyInfo.name, property2: conflictedField))
                }
                if var matchedChild = children[pathElementToMatch] {
                    try matchAndUpdate(&matchedChild, with: path.dropFirst(), field: field)
                    children[pathElementToMatch] = matchedChild
                    structure = .root(children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                } else {
                    if isLeaf {
                        if let sequenceElementCodingFieldInfo = field.sequenceElementCodingFieldInfo {
                            var subTree = nil as CodingSequenceSubStructure?
                            try CodingSequenceSubStructure.matchAndUpdateSequenceSubStructure(
                                &subTree, 
                                field: sequenceElementCodingFieldInfo, 
                                fieldName: field.propertyInfo.name
                            )
                            guard let subTree else { 
                                throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown) 
                            }
                            children[pathElementToMatch] = .sequenceLeaf(pathElement: pathElementToMatch, fields: [field], subTree: subTree)
                        } else {
                            children[pathElementToMatch] = .leaf(pathElement: pathElementToMatch, field: field)
                        }
                        structure = .root(children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    } else {
                        var newNode = CodingStructure.node(pathElement: pathElementToMatch, children: [:], requirementStrategy: field.requirementStrategy)
                        try matchAndUpdate(&newNode, with: path.dropFirst(), field: field)
                        children[pathElementToMatch] = newNode
                        structure = .root(children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    }
                }
            }
            case .node(let pathElement, var children, let requirementStrategy):
                guard let pathElementToMatch = path.first else {
                    guard let conflictedField = firstLeaf(in: structure) else {
                        throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown)
                    }
                    throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyInfo.name, property2: conflictedField))
                }
                guard children[pathElementToMatch] != nil else {
                    // no match found
                    if isLeaf {
                        if let sequenceElementCodingFieldInfo = field.sequenceElementCodingFieldInfo {
                            var subTree = nil as CodingSequenceSubStructure?
                            try CodingSequenceSubStructure.matchAndUpdateSequenceSubStructure(
                                &subTree, 
                                field: sequenceElementCodingFieldInfo, 
                                fieldName: field.propertyInfo.name
                            )
                            guard let subTree else { 
                                throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.codingStructureParsing.unknown) 
                            }
                            children[pathElementToMatch] = .sequenceLeaf(pathElement: pathElementToMatch, fields: [field], subTree: subTree)
                        } else {
                            children[pathElementToMatch] = .leaf(pathElement: pathElementToMatch, field: field)
                        }
                        structure = .node(pathElement: pathElement, children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    } else {
                        var newNode = CodingStructure.node(pathElement: pathElementToMatch, children: [:], requirementStrategy: field.requirementStrategy)
                        try matchAndUpdate(&newNode, with: path.dropFirst(), field: field)
                        children[pathElementToMatch] = newNode
                        structure = .node(pathElement: pathElement, children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    }
                    break
                }
                try matchAndUpdate(&children[pathElementToMatch]!, with: path.dropFirst(), field: field)
                structure = .node(pathElement: pathElement, children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                
        }
        
    }
    
    
    static func firstLeaf(
        in structure: CodingStructure
    ) -> TokenSyntax? {
        switch structure {
            case let .root(children, _):
                for child in children.values {
                    guard let first = firstLeaf(in: child) else { continue }
                    return first
                }
            case let .node(_, children, _):
                for child in children.values {
                    guard let first = firstLeaf(in: child) else { continue }
                    return first
                }
            case let .leaf(_, field):
                return field.propertyInfo.name
            case let .sequenceLeaf(_, fields, _):
                return fields.first?.propertyInfo.name
        }
        return nil
    }
    
}



indirect enum CodingSequenceSubStructure: Hashable, Equatable {

    case root(children: OrderedDictionary<String, CodingSequenceSubStructure>, requirementStrategy: CodableMacro.RequriementStrategy)
    case node(pathElement: String, children: OrderedDictionary<String, CodingSequenceSubStructure>, requirementStrategy: CodableMacro.RequriementStrategy)
    case leaf(pathElement: String?, field: CodableMacro.SequenceElementCodingFieldInfo)

    var pathElement: String? {
        switch self {
            case .root: nil
            case .node(let pathElement, _, _): pathElement
            case .leaf(let pathElement, _): pathElement
        }
    }

    var requirementStrategy: CodableMacro.RequriementStrategy {
        switch self {
            case let .root(_, requirementStrategy): requirementStrategy
            case let .node(_, _, requirementStrategy): requirementStrategy
            case let .leaf(_, field): field.requirementStrategy
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.pathElement)
    }

    static func ==== (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case let (.root(childrenL, strategyL), .root(childrenR, strategyR)): do {
                guard  strategyL == strategyR, childrenL.count == childrenR.count else { 
                    return false 
                }
                return childrenL.allSatisfy { (pathElement, childL) in
                    guard let childR = childrenR[pathElement] else { return false }
                    return childL ==== childR
                }
            }
            case let (.node(pathElementL, childrenL, strategyL), .node(pathElementR, childrenR, strategyR)): do {
                guard 
                    pathElementL == pathElementR,
                    strategyL == strategyR,
                    childrenL.count == childrenR.count
                else { return false }
                return childrenL.allSatisfy { (pathElement, childL) in
                    guard let childR = childrenR[pathElement] else { return false }
                    return childL ==== childR
                }
            }
            case let (.leaf(pathElementL, fieldL), .leaf(pathElementR, fieldR)): do {
                return pathElementL == pathElementR && fieldL == fieldR
            }
            default:
                return false
        }
    }

}



extension CodingSequenceSubStructure {

    static func matchAndUpdateSequenceSubStructure(
        _ structure: inout CodingSequenceSubStructure?,
        field: CodableMacro.SequenceElementCodingFieldInfo,
        fieldName: TokenSyntax
    ) throws(DiagnosticsError) {

        guard !field.path.isEmpty else { 
            if let structureCopy = structure {
                guard let conflictField = firstLeaf(in: structureCopy) else {
                    throw .diagnostic(node: fieldName, message: .codingMacro.codingStructureParsing.unknown)
                }
                throw .diagnostics(makePathConflictDiagnostics(property1: fieldName, property2: conflictField))
            } else  {
                structure = .leaf(pathElement: nil, field: field)
                return 
            }
        }

        var structureCopy = structure ?? .root(children: [:], requirementStrategy: .allowAll)
        try matchAndUpdate(&structureCopy, paths: field.path, field: field)
        structure = structureCopy

    }


    private static func matchAndUpdate<Path: Collection<String>>(
        _ structure: inout CodingSequenceSubStructure,
        paths: Path,
        field: CodableMacro.SequenceElementCodingFieldInfo
    ) throws(DiagnosticsError) {

        let isLeaf = (paths.count == 1)
        guard let pathElementToMatch = paths.first else { return }

        switch structure {

            case let .leaf(_, conflictField): do {
                throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyName, property2: conflictField.propertyName))
            }

            case .root(var children, let requirementStrategy): do {
                if var matchedChild = children[pathElementToMatch] {
                    // found a match
                    if isLeaf {
                        // found a match, but it is the last component of the path of the new property
                        // in this case, it should be a path conflict of some unknown internal error
                        guard let conflictFieldName = firstLeaf(in: structure) else {
                            throw .diagnostic(node: field.propertyName, message: .codingMacro.codingStructureParsing.unknown)
                        }
                        throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyName, property2: conflictFieldName))
                    } else {
                        // found a match, but it is not the last component of the path of the new property
                        // in this case, we need to continue matching
                        try matchAndUpdate(&matchedChild, paths: paths.dropFirst(), field: field)
                        children[pathElementToMatch] = matchedChild
                        structure = .root(children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    }
                } else {
                    // no match found
                    if isLeaf {
                        children[pathElementToMatch] = .leaf(pathElement: pathElementToMatch, field: field)
                        structure = .root(children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    } else {
                        var newNode = CodingSequenceSubStructure.node(pathElement: pathElementToMatch, children: [:], requirementStrategy: field.requirementStrategy)
                        try matchAndUpdate(&newNode, paths: paths.dropFirst(), field: field)
                        children[pathElementToMatch] = newNode
                        structure = .root(children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    }
                }
            }

            case .node(let pathElement, var children, let requirementStrategy): do {
                if var matchedChild = children[pathElementToMatch] {
                    // found a match
                    if isLeaf {
                        // found a match, but it is the last component of the path of the new property
                        // in this case, it should be a path conflict of some unknown internal error
                        guard let conflictFieldName = firstLeaf(in: structure) else {
                            throw .diagnostic(node: field.propertyName, message: .codingMacro.codingStructureParsing.unknown)
                        }
                        throw .diagnostics(makePathConflictDiagnostics(property1: field.propertyName, property2: conflictFieldName))
                    } else {
                        // found a match, but it is not the last component of the path of the new property
                        // in this case, we need to continue matching
                        try matchAndUpdate(&matchedChild, paths: paths.dropFirst(), field: field)
                        children[pathElementToMatch] = matchedChild
                        structure = .node(pathElement: pathElement, children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    }
                } else {
                    // no match found
                    if isLeaf {
                        children[pathElementToMatch] = .leaf(pathElement: pathElementToMatch, field: field)
                        structure = .node(pathElement: pathElement, children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    } else {
                        var newNode = CodingSequenceSubStructure.node(pathElement: pathElementToMatch, children: [:], requirementStrategy: field.requirementStrategy)
                        try matchAndUpdate(&newNode, paths: paths.dropFirst(), field: field)
                        children[pathElementToMatch] = newNode
                        structure = .node(pathElement: pathElement, children: children, requirementStrategy: requirementStrategy | field.requirementStrategy)
                    }
                }
            }

        }

    }


    private static func firstLeaf(
        in structure: CodingSequenceSubStructure
    ) -> TokenSyntax? {
        switch structure {
            case let .root(children, _), let .node(_, children, _):
                for child in children.values {
                    guard let first = firstLeaf(in: child) else { continue }
                    return first
                }
            case let .leaf(_, field):
                return field.propertyName
        }
        return nil
    }

}



fileprivate func makePathConflictDiagnostics(
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



extension CodingMacroDiagnosticMessageGroup {
    static var codingStructureParsing: CodingStructureParsingError.Type {
        CodingStructureParsingError.self
    }
}