import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



// MARK: Standard Decode
extension CodableMacro {

    func generateDecodeInitializer(from structure: CodingStructure) throws -> DeclSyntax {

        var containerStack: [CodingContainerName] = []

        func structureDfs(_ structure: CodingStructure) throws -> (items: [CodeBlockItemSyntax], fieldsToInitOnError: [CodingFieldInfo]) {

            var codeBlockItems = [CodeBlockItemSyntax]()
            var fieldsToInitOnError = [CodingFieldInfo]()

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

                case let .leaf(pathElement, field): do {

                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    let propertyInfo = field.propertyInfo

                    if (
                        field.defaultValueOnMisMatch != nil || field.defaultValueOnMissing != nil 
                        || (propertyInfo.initializer == nil && propertyInfo.hasOptionalTypeDecl) 
                    ) {
                        fieldsToInitOnError.append(field)
                    }

                    guard propertyInfo.type != .constant || propertyInfo.initializer == nil else {
                        // a let constant with an initializer cannot be decoded, ignore it
                        break
                    }

                    codeBlockItems.append(
                        try generateStandardDecodeBlock(field: field, container: parentContainer, pathElement: pathElement)
                    )

                }

                case let .sequenceLeaf(pathElement, fields, subTree): do {
                    
                    guard let parentContainer = containerStack.last else {
                        throw InternalError(message: "unexpected empty container stack")
                    }
                    let container = parentContainer.childContainer(with: pathElement)

                    fieldsToInitOnError.append(
                        contentsOf: fields.filter { 
                            $0.defaultValueOnMisMatch != nil || $0.defaultValueOnMissing != nil 
                            || ($0.propertyInfo.initializer == nil && $0.propertyInfo.hasOptionalTypeDecl)  
                        }
                    )

                    containerStack.append(container)
                    defer { containerStack.removeLast() }

                    let expr = try generateSequenceLeafDecodeBlock(
                        fields: fields, 
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
        fieldsToInitOnError: [CodingFieldInfo]
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
        fieldsToInitOnError: [CodingFieldInfo]
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
        fieldsToInitOnError: [CodingFieldInfo]
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


    private func generateStandardDecodeBlock(field: CodingFieldInfo, container: CodingContainerName, pathElement: String) throws -> CodeBlockItemSyntax {

        var typeExpression: ExprSyntax {
            get throws {
                if let typeExpr = field.decodeTransform?.decodeSourceType { return typeExpr }
                if let typeExpr = field.propertyInfo.typeExpression { return typeExpr }
                throw .diagnostic(node: field.propertyInfo.name, message: .codingMacro.general.cannotInferType)
            }
        }

        var doStmt = try DoStmtSyntax("do") {
            "let rawValue = \(try GenerationItems.decodeExpr(container: container, pathElement: pathElement, type: typeExpression))"
            try makeDecodeTransformExprs(field: field, sourceVarName: "rawValue", destVarName: "value")
            try makeValidateionExprs(field: field, varName: "value")
            "self.\(field.propertyInfo.name) = value"
        }

        if field.requirementStrategy.allowMismatch {
            try doStmt.addCatchClause(errors: [GenerationItems.typeMismatchErrorExpr]) {
                if let defaultValue = field.defaultValueOnMisMatch {
                    "self.\(field.propertyInfo.name) = \(defaultValue)"
                } else if field.propertyInfo.initializer == nil, field.propertyInfo.hasOptionalTypeDecl {
                    "self.\(field.propertyInfo.name) = nil"
                }
            }
        }
        if field.requirementStrategy.allowMissing {
            try doStmt.addCatchClause(errors: [GenerationItems.valueNotFoundErrorExpr, GenerationItems.keyNotFoundErrorExpr]) {
                if let defaultValue = field.defaultValueOnMissing {
                    "self.\(field.propertyInfo.name) = \(defaultValue)"
                } else if field.propertyInfo.initializer == nil, field.propertyInfo.hasOptionalTypeDecl {
                    "self.\(field.propertyInfo.name) = nil"
                }
            }
        }

        return .init(item: .stmt(.init(doStmt)))

    }


    private func generateSequenceLeafDecodeBlock(
        fields: [CodingFieldInfo],
        parentContainer: CodingContainerName,
        pathElement: String,
        childSequenceDecodeItems: [CodeBlockItemSyntax],
        fieldsToInitOnError: [CodingFieldInfo]
    ) throws -> CodeBlockItemSyntax {

        let container = parentContainer.childContainer(with: pathElement)

        var expr = try DoStmtSyntax("do") {
            GenerationItems.decodeNestedUnkeyedContainerStmt(parentContainer: parentContainer, pathElement: pathElement)
            for field in fields {
                if let sequenceElementCodingInfo = field.sequenceCodingFieldInfo {
                    let typeExpr = sequenceElementCodingInfo.elementEncodedType 
                    let makeEmptyArrExpr = "\(GenerationItems.makeEmptyArrayFunctionName)(ofType: \(typeExpr))" as ExprSyntax
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: field.propertyInfo.name)
                    "var \(sequenceDecodeTempVarName) = \(makeEmptyArrExpr)"
                } else {
                    throw InternalError(message: "Expected sequence element coding info")
                }
            }
            try WhileStmtSyntax("while !\(container.varName).isAtEnd") {
                childSequenceDecodeItems
            }
            for field in fields {
                if let sequenceElementCodingInfo = field.sequenceCodingFieldInfo {
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: field.propertyInfo.name)
                    try DoStmtSyntax("do") {
                        GenerationItems.makeSingleTransformStmt(source: sequenceDecodeTempVarName, transform: sequenceElementCodingInfo.decodeTransformExpr, target: "rawValue")
                        try makeDecodeTransformExprs(field: field, sourceVarName: "rawValue", destVarName: "value")
                        try makeValidateionExprs(field: field, varName: "value")
                        "self.\(field.propertyInfo.name) = value"
                    }
                } else {
                    throw InternalError(message: "Expected sequence element coding info")
                }
            }
        }

        try addStandardCatchClauses(
            to: &expr, 
            fieldsWithDefault: fieldsToInitOnError, 
            requirementStrategy: fields.reduce(.allowAll) { $0 | $1.requirementStrategy }
        )

        return .init(item: .stmt(.init(expr)))

    }


    private func addStandardCatchClauses(
        to doStmt: inout DoStmtSyntax, 
        fieldsWithDefault: [CodingFieldInfo], 
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
        _ fieldsToInitOnError: [CodingFieldInfo], 
        type: RequriementStrategy
    ) throws -> [CodeBlockItemSyntax] {

        let defaultValueKeyPath = switch type {
            case .allowMismatch: \.defaultValueOnMisMatch
            case .allowMissing: \.defaultValueOnMissing
            case .allowAll: throw InternalError(message: "Unexpected `.allowAll` requirement strategy when generating default value assignment")
            case .always: throw InternalError(message: "Unexpected `.always` requirement strategy when generating default value assignment")
        } as KeyPath<CodableMacro.CodingFieldInfo, ExprSyntax?>

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

            case let .leaf(pathElement, field): do {

                guard let parentContainer = containerStack.last else {
                    throw InternalError(message: "unexpected empty container stack")
                }

                if field.requirementStrategy != .always {
                    fieldsToInitOnError.append(field)
                }

                let expr = try generateSequenceElementDecodeBlock(field: field, container: parentContainer, pathElement: pathElement)
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
                fields: fieldsToInitOnError, 
                requirementStrategy: requirementStrategy, 
                containerSkipElementExpr: containerSkipElementExpr
            )
            codeBlockItems.append(.init(item: .stmt(.init(expr))))
        }
        return codeBlockItems
    }


    private func generateSequenceElementDecodeBlock(
        field: SequenceCodingFieldInfo,
        container: CodingContainerName,
        pathElement: String?
    ) throws -> CodeBlockItemSyntax {

        let containerVarName = container.varName
        let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: field.propertyName)

        var expr = try DoStmtSyntax("do") {
            if let pathElement {
                "let rawValue = \(GenerationItems.decodeExpr(container: container, pathElement: pathElement, type: field.elementEncodedType))"
            } else {
                "let rawValue = \(GenerationItems.decodeExpr(unkeyedContainer: container, type: field.elementEncodedType))"
            }
            "\(sequenceDecodeTempVarName).append(rawValue)" as CodeBlockItemSyntax
        }

        if field.requirementStrategy.allowMissing {
            try expr.addCatchClause(errors: [GenerationItems.keyNotFoundErrorExpr, GenerationItems.valueNotFoundErrorExpr]) {
                switch field.defaultValueOnMissing {
                    case .value(let value): "\(sequenceDecodeTempVarName).append(\(value))"
                    default: ""
                }
                if pathElement == nil {
                    "try \(containerVarName).skip()"
                }
            }
        }
        if field.requirementStrategy.allowMismatch {
            try expr.addCatchClause(errors: [GenerationItems.typeMismatchErrorExpr]) {
                switch field.defaultValueOnMismatch {
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
        fields: [SequenceCodingFieldInfo],
        requirementStrategy: RequriementStrategy,
        containerSkipElementExpr: CodeBlockItemSyntax? = nil 
    ) throws {

        if requirementStrategy.allowMissing {
            try doStmt.addCatchClause(errors: [GenerationItems.keyNotFoundErrorExpr]) {
                fields.compactMap { field in 
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: field.propertyName)
                    return switch field.defaultValueOnMissing {
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
                fields.compactMap { field in 
                    let sequenceDecodeTempVarName = GenerationItems.sequenceCodingTempVarName(of: field.propertyName)
                    return switch field.defaultValueOnMismatch {
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

    fileprivate func makeDecodeTransformExprs(field: CodingFieldInfo, sourceVarName: TokenSyntax, destVarName: TokenSyntax) throws -> [CodeBlockItemSyntax] {
        if let transformSpec = field.decodeTransform {
            transformSpec.transformExprs.enumerated().map { i, transform in
                let localSourceVarName = i == 0 ? sourceVarName : "value\(raw: i)" as TokenSyntax
                let localDestVarName = i == transformSpec.transformExprs.count - 1 ? destVarName : "value\(raw: i + 1)" as TokenSyntax
                return GenerationItems.makeSingleTransformStmt(source: localSourceVarName, transform: transform, target: localDestVarName)
            }
        } else {
            ["let \(destVarName) = \(sourceVarName)"]
        }
    }


    fileprivate func makeValidateionExprs(field: CodingFieldInfo, varName: TokenSyntax) throws -> [CodeBlockItemSyntax] {
        field.validateExprs.map { expr in
            let exprString = StringLiteralExprSyntax(content: IndentRemover().visit(expr).formatted().description)
            return #"try \#(GenerationItems.validateFunctionName)("\#(field.propertyInfo.name)", \#(exprString), \#(varName), \#(expr))"#
        }
    }

}



extension DoStmtSyntax {

    fileprivate mutating func addCatchClause(
        errors: [ExprSyntax], 
        @CodeBlockItemListBuilder bodyBuilder: () throws -> CodeBlockItemListSyntax
    ) throws {

        let catchItems = errors.enumerated().map { i, error in 
            let traiilingTrivia = (i == errors.count - 1 ? nil : ", ") as Trivia?
            return CatchItemSyntax(pattern: ExpressionPatternSyntax(expression: error, trailingTrivia: traiilingTrivia)) 
        }

        self.catchClauses.append(
            try CatchClauseSyntax(
                catchItems: .init(catchItems), 
                bodyBuilder: bodyBuilder
            ) 
        )

    }

}