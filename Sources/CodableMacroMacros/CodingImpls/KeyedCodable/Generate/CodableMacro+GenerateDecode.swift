import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



// MARK: Standard Decode
extension CodableMacro {

    func generateDecodeInitializer(from structure: CodingStructure) throws -> DeclSyntax {

        var containerStack: [CodingContainerName] = []

        func structureDfs(_ structure: CodingStructure) throws -> (items: [CodeBlockItemSyntax], fieldsToInitOnError: [PropertyCodingSpec]) {

            var codeBlockItems = [CodeBlockItemSyntax]()
            var fieldsToInitOnError = [PropertyCodingSpec]()

            switch structure {

                case let .root(children, requirementStrategy): do {

                    let container = "root" as CodingContainerName

                    containerStack.append(container)
                    defer { containerStack.removeLast() }

                    let items = try children.values.flatMap { child in
                        let (childItems, childFieldsToInitOnError) = try structureDfs(child)
                        fieldsToInitOnError.append(contentsOf: childFieldsToInitOnError)
                        return childItems
                    }
                    guard !items.isEmpty else { break }

                    codeBlockItems = try generateStandardRootDecodeItems(
                        container: container,
                        requirementStrategy: requirementStrategy,
                        childDecodingItems: items, 
                        fieldsToInitOnError: fieldsToInitOnError
                    )

                }

                case let .node(pathElement, children, requirementStrategy): do {

                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    let container = parentContainer.childContainer(with: pathElement)

                    containerStack.append(container)
                    defer { containerStack.removeLast() }

                    let items = try children.values.flatMap { child in
                        let (childItems, childFieldsWithDefault) = try structureDfs(child)
                        fieldsToInitOnError.append(contentsOf: childFieldsWithDefault)
                        return childItems
                    }

                    guard !items.isEmpty else { break }

                    codeBlockItems = try generateStandardContainerDecodeItems(
                        parentContainer: parentContainer,
                        pathElement: pathElement, 
                        requirementStrategy: requirementStrategy, 
                        childDecodingItems: items, 
                        fieldsToInitOnError: fieldsToInitOnError
                    )

                }

                case let .leaf(pathElement, spec): do {

                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    let propertyInfo = spec.propertyInfo

                    if (
                        spec.defaultValueOnMisMatch != nil || spec.defaultValueOnMissing != nil 
                        || (propertyInfo.initializer == nil && propertyInfo.hasOptionalTypeDecl) 
                    ) {
                        fieldsToInitOnError.append(spec)
                    }

                    guard propertyInfo.type != .constant || propertyInfo.initializer == nil else {
                        // a let constant with an initializer cannot be decoded, ignore it
                        break
                    }

                    codeBlockItems.append(
                        try generateStandardDecodeBlock(spec: spec, container: parentContainer, pathElement: pathElement)
                    )

                }

                case let .sequenceLeaf(pathElement, specs, subTree): do {
                    
                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    let container = parentContainer.childContainer(with: pathElement)

                    fieldsToInitOnError.append(
                        contentsOf: specs.filter { 
                            $0.defaultValueOnMisMatch != nil || $0.defaultValueOnMissing != nil 
                            || ($0.propertyInfo.initializer == nil && $0.propertyInfo.hasOptionalTypeDecl)  
                        }
                    )

                    containerStack.append(container)
                    defer { containerStack.removeLast() }

                    let expr = try generateSequenceLeafDecodeBlock(
                        specs: specs, 
                        parentContainer: parentContainer, 
                        pathElement: pathElement, 
                        childSequenceDecodeItems: generateSequenceDecodeItems(from: subTree, containerStack: &containerStack).items, 
                        fieldsToInitOnError: fieldsToInitOnError
                    )
                    codeBlockItems.append(expr)

                }

            }

            return (codeBlockItems, fieldsToInitOnError)

        }

        let isClass = declGroup.type == .class

        return .init(
            try InitializerDeclSyntax("public \(raw: isClass ? "required " : "")init(from decoder: Decoder) throws") {
                GenerationItems.transformFunctionDecl
                GenerationItems.validationFunctionDecl
                GenerationItems.makeEmptyArrayFunctionDecl
                try structureDfs(structure).items
                if inherit {
                    "try super.init(from: decoder)"
                }
            }
        )

    }


    private func generateStandardRootDecodeItems(
        container: CodingContainerName,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [PropertyCodingSpec]
    ) throws -> [CodeBlockItemSyntax] {

        return try generateStandardContainerDecodeItems(
            decodeStmt: GenerationItems.decodeNestedContainerStmt(container: container),
            requirementStrategy: requirementStrategy,
            childDecodingItems: childDecodingItems,
            fieldsToInitOnError: fieldsToInitOnError
        )

    }


    private func generateStandardContainerDecodeItems(
        parentContainer: CodingContainerName,
        pathElement: String,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [PropertyCodingSpec]
    ) throws -> [CodeBlockItemSyntax] {

        return try generateStandardContainerDecodeItems(
            decodeStmt: GenerationItems.decodeNestedContainerStmt(
                parentContainer: parentContainer, 
                pathElement: pathElement
            ),
            requirementStrategy: requirementStrategy,
            childDecodingItems: childDecodingItems,
            fieldsToInitOnError: fieldsToInitOnError
        )

    }


    private func generateStandardContainerDecodeItems(
        decodeStmt: CodeBlockItemSyntax,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [PropertyCodingSpec]
    ) throws -> [CodeBlockItemSyntax] {
        var codeBlockItems = [CodeBlockItemSyntax]()
        if requirementStrategy == .always {
            codeBlockItems.append(decodeStmt)
            codeBlockItems.append(contentsOf: childDecodingItems)
        } else {
            var expr = try DoStmtSyntax("do") {
                decodeStmt
                childDecodingItems
            }
            try addStandardCatchClauses(to: &expr, fieldsWithDefault: fieldsToInitOnError, requirementStrategy: requirementStrategy)
            codeBlockItems.append(.init(item: .stmt(.init(expr))))
        }
        return codeBlockItems
    }


    private func generateStandardDecodeBlock(spec: PropertyCodingSpec, container: CodingContainerName, pathElement: String) throws -> CodeBlockItemSyntax {

        var typeExpression: ExprSyntax {
            get throws {
                if let typeExpr = spec.decodeTransform?.decodeSourceType { return typeExpr }
                if let typeExpr = spec.propertyInfo.typeExpression { return typeExpr }
                throw .diagnostic(node: spec.propertyInfo.name, message: .codingMacro.general.cannotInferType)
            }
        }

        var doStmt = try DoStmtSyntax("do") {
            "let rawValue = \(try GenerationItems.decodeExpr(container: container, pathElement: pathElement, type: typeExpression))"
            try makeDecodeTransformExprs(spec: spec, sourceVarName: "rawValue", destVarName: "value")
            try makeValidateionExprs(spec: spec, varName: "value")
            "self.\(spec.propertyInfo.name) = value"
        }

        if spec.requirementStrategy.allowMismatch {
            try doStmt.addCatchClause(errors: [GenerationItems.typeMismatchErrorExpr]) {
                if let defaultValue = spec.defaultValueOnMisMatch {
                    "self.\(spec.propertyInfo.name) = \(defaultValue)"
                } else if spec.propertyInfo.initializer == nil, spec.propertyInfo.hasOptionalTypeDecl {
                    "self.\(spec.propertyInfo.name) = nil"
                }
            }
        }
        if spec.requirementStrategy.allowMissing {
            try doStmt.addCatchClause(errors: [GenerationItems.valueNotFoundErrorExpr, GenerationItems.keyNotFoundErrorExpr]) {
                if let defaultValue = spec.defaultValueOnMissing {
                    "self.\(spec.propertyInfo.name) = \(defaultValue)"
                } else if spec.propertyInfo.initializer == nil, spec.propertyInfo.hasOptionalTypeDecl {
                    "self.\(spec.propertyInfo.name) = nil"
                }
            }
        }

        return .init(item: .stmt(.init(doStmt)))

    }


    private func generateSequenceLeafDecodeBlock(
        specs: [PropertyCodingSpec],
        parentContainer: CodingContainerName,
        pathElement: String,
        childSequenceDecodeItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [PropertyCodingSpec]
    ) throws -> CodeBlockItemSyntax {

        let container = parentContainer.childContainer(with: pathElement)

        var expr = try DoStmtSyntax("do") {
            GenerationItems.decodeNestedUnkeyedContainerStmt(parentContainer: parentContainer, pathElement: pathElement)
            for spec in specs {
                if let sequenceElementCodingInfo = spec.sequenceCodingFieldInfo {
                    let typeExpr = sequenceElementCodingInfo.elementEncodedType 
                    let makeEmptyArrExpr = "\(GenerationItems.makeEmptyArrayFunctionName)(ofType: \(typeExpr))" as ExprSyntax
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: spec.propertyInfo.name)
                    "var \(sequenceDecodeTempVarName) = \(makeEmptyArrExpr)"
                } else {
                    throw InternalError(message: "Expected sequence element coding info")
                }
            }
            try WhileStmtSyntax("while !\(container.varName).isAtEnd") {
                childSequenceDecodeItems
            }
            for spec in specs {
                if let sequenceElementCodingInfo = spec.sequenceCodingFieldInfo {
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: spec.propertyInfo.name)
                    try DoStmtSyntax("do") {
                        GenerationItems.makeSingleTransformStmt(source: sequenceDecodeTempVarName, transform: sequenceElementCodingInfo.decodeTransformExpr, target: "rawValue")
                        try makeDecodeTransformExprs(spec: spec, sourceVarName: "rawValue", destVarName: "value")
                        try makeValidateionExprs(spec: spec, varName: "value")
                        "self.\(spec.propertyInfo.name) = value"
                    }
                } else {
                    throw InternalError(message: "Expected sequence element coding info")
                }
            }
        }

        try addStandardCatchClauses(
            to: &expr, 
            fieldsWithDefault: fieldsToInitOnError, 
            requirementStrategy: specs.reduce(.allowAll) { $0 | $1.requirementStrategy }
        )

        return .init(item: .stmt(.init(expr)))

    }


    private func addStandardCatchClauses(
        to doStmt: inout DoStmtSyntax, 
        fieldsWithDefault: [PropertyCodingSpec], 
        requirementStrategy: RequriementStrategy
    ) throws {

        if requirementStrategy.allowMismatch {
            try doStmt.addCatchClause(errors: [GenerationItems.typeMismatchErrorExpr]) {
                try initFieldsWithDefaultCodeBlockItems(fieldsWithDefault, type: .allowMismatch)
            }
        }

        if requirementStrategy.allowMissing {
            try doStmt.addCatchClause(errors: [GenerationItems.keyNotFoundErrorExpr]) {
                try initFieldsWithDefaultCodeBlockItems(fieldsWithDefault, type: .allowMissing)
            }
        }

    }


    private func initFieldsWithDefaultCodeBlockItems(
        _ fieldsToInitOnError: [PropertyCodingSpec], 
        type: RequriementStrategy
    ) throws -> [CodeBlockItemSyntax] {

        let defaultValueKeyPath = switch type {
            case .allowMismatch: \.defaultValueOnMisMatch
            case .allowMissing: \.defaultValueOnMissing
            case .allowAll: throw InternalError(message: "Unexpected `.allowAll` requirement strategy when generating default value assignment")
            case .always: throw InternalError(message: "Unexpected `.always` requirement strategy when generating default value assignment")
        } as KeyPath<CodableMacro.PropertyCodingSpec, ExprSyntax?>

        return try fieldsToInitOnError.map { 
            if let defaultValue = $0[keyPath: defaultValueKeyPath] {
                "self.\($0.propertyInfo.name) = \(defaultValue)"
            } else if $0.propertyInfo.initializer == nil, $0.propertyInfo.hasOptionalTypeDecl {
                "self.\($0.propertyInfo.name) = nil"
            } else {
                throw .diagnostic(node: $0.propertyInfo.name, message: .codingMacro.codable.missingDefaultOrOptional)
            }
        }

    }

}



// MARK: Sequence Element Decode
extension CodableMacro {

    fileprivate func generateSequenceDecodeItems(
        from structure: SequenceCodingSubStructure,
        containerStack: inout [CodingContainerName]
    ) throws -> (items: [CodeBlockItemSyntax], fieldsWithDefault: [SequenceCodingFieldInfo]) {

        var codeBlockItems = [CodeBlockItemSyntax]()
        var fieldsToInitOnError = [SequenceCodingFieldInfo]()

        switch structure {

            case let .root(children, requirementStrategy): do {

                guard let parentUnkeyedContainer = containerStack.last else {
                    throw InternalError(message: "unexpected empty container stack")
                }
                let container = parentUnkeyedContainer.childContainer(with: "root")

                containerStack.append(container)
                defer { containerStack.removeLast() }

                let items = try children.values.flatMap { 
                    let (items, childFieldsToInitOnError) = try generateSequenceDecodeItems(from: $0, containerStack: &containerStack)
                    fieldsToInitOnError.append(contentsOf: childFieldsToInitOnError)
                    return items
                }

                codeBlockItems = try generateSequenceElementRootDecodeItems(
                    parentUnkeyedContainer: parentUnkeyedContainer, 
                    requirementStrategy: requirementStrategy, 
                    childDecodingItems: items, 
                    fieldsToInitOnError: fieldsToInitOnError
                )

            }

            case let .node(pathElement, children, requirementStrategy): do {

                guard let parentContainer = containerStack.last else {
                    throw InternalError(message: "unexpected empty container stack")
                }
                let container = parentContainer.childContainer(with: pathElement)

                containerStack.append(container)
                defer { containerStack.removeLast() }

                let items = try children.values.flatMap { 
                    let (items, childFieldsToInitOnError) = try generateSequenceDecodeItems(from: $0, containerStack: &containerStack)
                    fieldsToInitOnError.append(contentsOf: childFieldsToInitOnError)
                    return items
                }

                codeBlockItems = try generateSequenceElementContainerDecodeItems(
                    parentContainer: parentContainer, 
                    pathElement: pathElement, 
                    requirementStrategy: requirementStrategy, 
                    childDecodingItems: items, 
                    fieldsToInitOnError: fieldsToInitOnError
                )

            }

            case let .leaf(pathElement, spec): do {

                guard let parentContainer = containerStack.last else {
                    throw InternalError(message: "unexpected empty container stack")
                }

                if spec.requirementStrategy != .always {
                    fieldsToInitOnError.append(spec)
                }

                let expr = try generateSequenceElementDecodeBlock(spec: spec, container: parentContainer, pathElement: pathElement)
                codeBlockItems.append(expr)

            } 
        }

        return (codeBlockItems, fieldsToInitOnError)

    }


    private func generateSequenceElementRootDecodeItems(
        parentUnkeyedContainer: CodingContainerName,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [SequenceCodingFieldInfo]
    ) throws -> [CodeBlockItemSyntax] {

        return try generateSequenceElementContainerDecodeItems(
            decodeExpr: GenerationItems.decodeNestedContainerStmt(parentUnkeyedContainer: parentUnkeyedContainer),
            requirementStrategy: requirementStrategy, 
            childDecodingItems: childDecodingItems, 
            fieldsToInitOnError: fieldsToInitOnError,
            containerSkipElementExpr: "try \(parentUnkeyedContainer.varName).skip()"
        )

    }


    private func generateSequenceElementContainerDecodeItems(
        parentContainer: CodingContainerName,
        pathElement: String,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [SequenceCodingFieldInfo]
    ) throws -> [CodeBlockItemSyntax] {

        return try generateSequenceElementContainerDecodeItems(
            decodeExpr: GenerationItems.decodeNestedContainerStmt(parentContainer: parentContainer, pathElement: pathElement), 
            requirementStrategy: requirementStrategy, 
            childDecodingItems: childDecodingItems, 
            fieldsToInitOnError: fieldsToInitOnError
        )

    }


    private func generateSequenceElementContainerDecodeItems(
        decodeExpr: CodeBlockItemSyntax,
        requirementStrategy: RequriementStrategy,
        childDecodingItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [SequenceCodingFieldInfo],
        containerSkipElementExpr: CodeBlockItemSyntax? = nil
    ) throws -> [CodeBlockItemSyntax] {
        var codeBlockItems = [CodeBlockItemSyntax]()
        if requirementStrategy == .always {
            codeBlockItems.append(decodeExpr)
            codeBlockItems.append(contentsOf: childDecodingItems)
        } else {
            var expr = try DoStmtSyntax("do") {
                decodeExpr
                childDecodingItems
            }
            try addSequenceElementCatchBlock(
                to: &expr, 
                specs: fieldsToInitOnError, 
                requirementStrategy: requirementStrategy, 
                containerSkipElementExpr: containerSkipElementExpr
            )
            codeBlockItems.append(.init(item: .stmt(.init(expr))))
        }
        return codeBlockItems
    }


    private func generateSequenceElementDecodeBlock(
        spec: SequenceCodingFieldInfo,
        container: CodingContainerName,
        pathElement: String?
    ) throws -> CodeBlockItemSyntax {

        let containerVarName = container.varName
        let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: spec.propertyName)

        var expr = try DoStmtSyntax("do") {
            if let pathElement {
                "let rawValue = \(GenerationItems.decodeExpr(container: container, pathElement: pathElement, type: spec.elementEncodedType))"
            } else {
                "let rawValue = \(GenerationItems.decodeExpr(unkeyedContainer: container, type: spec.elementEncodedType))"
            }
            "\(sequenceDecodeTempVarName).append(rawValue)" as CodeBlockItemSyntax
        }

        if spec.requirementStrategy.allowMissing {
            try expr.addCatchClause(errors: [GenerationItems.keyNotFoundErrorExpr, GenerationItems.valueNotFoundErrorExpr]) {
                switch spec.defaultValueOnMissing {
                    case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                    default: ""
                }
                if pathElement == nil {
                    "try \(containerVarName).skip()"
                }
            }
        }
        if spec.requirementStrategy.allowMismatch {
            try expr.addCatchClause(errors: [GenerationItems.typeMismatchErrorExpr]) {
                switch spec.defaultValueOnMismatch {
                    case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                    default: ""
                }
                if pathElement == nil {
                    "try \(containerVarName).skip()"
                }
            }
        }

        return .init(item: .stmt(.init(expr)))

    }


    private func addSequenceElementCatchBlock(
        to doStmt: inout DoStmtSyntax,
        specs: [SequenceCodingFieldInfo],
        requirementStrategy: RequriementStrategy,
        containerSkipElementExpr: CodeBlockItemSyntax? = nil 
    ) throws {

        if requirementStrategy.allowMissing {
            try doStmt.addCatchClause(errors: [GenerationItems.keyNotFoundErrorExpr]) {
                specs.compactMap { spec in 
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: spec.propertyName)
                    return switch spec.defaultValueOnMissing {
                        case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                        default: nil 
                    }
                }
                if let containerSkipElementExpr {
                    containerSkipElementExpr
                }
            }
        }
        if requirementStrategy.allowMismatch {
            try doStmt.addCatchClause(errors: [GenerationItems.typeMismatchErrorExpr]) {
                specs.compactMap { spec in 
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: spec.propertyName)
                    return switch spec.defaultValueOnMismatch {
                        case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                        default: nil 
                    }
                }
                if let containerSkipElementExpr {
                    containerSkipElementExpr
                }
            }
        }

    }

}



// MARK: Shared Helpers
extension CodableMacro {

    fileprivate func makeDecodeTransformExprs(spec: PropertyCodingSpec, sourceVarName: TokenSyntax, destVarName: TokenSyntax) throws -> [CodeBlockItemSyntax] {
        if let transformSpec = spec.decodeTransform {
            transformSpec.transformExprs.enumerated().map { i, transform in
                let localSourceVarName = i == 0 ? sourceVarName : "value\(raw: i)" as TokenSyntax
                let localDestVarName = i == transformSpec.transformExprs.count - 1 ? destVarName : "value\(raw: i + 1)" as TokenSyntax
                return GenerationItems.makeSingleTransformStmt(source: localSourceVarName, transform: transform, target: localDestVarName)
            }
        } else {
            ["let \(destVarName) = \(sourceVarName)"]
        }
    }


    fileprivate func makeValidateionExprs(spec: PropertyCodingSpec, varName: TokenSyntax) throws -> [CodeBlockItemSyntax] {
        spec.validateExprs.map { expr in
            let exprString = StringLiteralExprSyntax(content: IndentRemover().visit(expr).formatted().description)
            return #"try \#(GenerationItems.validateFunctionName)("\#(spec.propertyInfo.name)", \#(exprString), \#(varName), \#(expr))"#
        }
    }

}