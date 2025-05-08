import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics



extension CodableMacro {

    enum GenerationItems {

        static let containerCodingKeysPrefix: TokenSyntax = "$__coding_container_keys_"
        static let containerVarNamePrefix: TokenSyntax = "$__coding_container_"
        static let sequenceCodingTempVarNamePrefix: TokenSyntax = "$__sequence_coding_temp_"
        static let sequenceCodingElementVarNamePrefix: TokenSyntax = "$__sequence_coding_element_"

        static let typeMismatchErrorExpr: ExprSyntax = "Swift.DecodingError.typeMismatch"
        static let keyNotFoundErrorExpr: ExprSyntax = "Swift.DecodingError.keyNotFound"
        static let valueNotFoundErrorExpr: ExprSyntax = "Swift.DecodingError.valueNotFound"

        static let transformFunctionName: TokenSyntax = "$__coding_transform"
        static let validateFunctionName: TokenSyntax = "$__coding_validate"
        static let makeEmptyArrayFunctionName: TokenSyntax = "$__coding_make_empty_array"

        static var transformFunctionDecl: DeclSyntax {
            """
            func \(transformFunctionName)<T, R>(_ value: T, _ transform: (T) throws -> R) throws -> R {
                return try transform(value)
            }
            """
        }

        static var validationFunctionDecl: DeclSyntax {
            #"""
            func \#(validateFunctionName)<T>(_ propertyName: String, _ validateExpr: String, _ value: T, _ validate: (T) throws -> Bool) throws {
                guard (try? validate(value)) == true else {
                    throw CodingValidationError(type: "\(Self.self)", property: propertyName, validationExpr: validateExpr, value: "\(value as Any)")
                }
            }
            """#
        }

        static var makeEmptyArrayFunctionDecl: DeclSyntax {
            """
            func \(makeEmptyArrayFunctionName)<T>(ofType type: T.Type) -> [T] {
                return []
            }
            """
        }


        static func codingKeysName(of containerName: TokenSyntax) -> TokenSyntax {
            "\(containerCodingKeysPrefix)\(containerName)"
        }


        static func containerVarName(of containerName: TokenSyntax) -> TokenSyntax {
            "\(containerVarNamePrefix)\(containerName)"
        }


        /// Return the name of the temporary variable holding the raw sequence for encoding/decoding a given sequence property.
        /// - Parameter propertyName: The name of the property being encoded/decoded.
        /// - Returns: The name of the temporary variable.
        static func sequenceCodingTempVarName(of propertyName: TokenSyntax) -> TokenSyntax {
            "\(sequenceCodingTempVarNamePrefix)\(propertyName)"
        }


        static func sequenceCodingElementVarName(of propertyName: TokenSyntax) -> TokenSyntax {
            "\(sequenceCodingElementVarNamePrefix)\(propertyName)"
        }


        static func keyAccessor(for pathElement: String) -> MemberAccessExprSyntax {
            .init(name: "\(raw: pathElement)")
        }


        static func containerName(byAppending pathElement: String, to baseContainerName: TokenSyntax) -> TokenSyntax {
            "\(baseContainerName)_\(raw: pathElement)"
        }


        static func makeSingleTransformStmt(source: TokenSyntax, transform: ExprSyntax?, target: TokenSyntax) -> CodeBlockItemSyntax {
            return "let \(target) = \(makeSingleTransformExpr(source: source, transform: transform))"
        }


        static func makeSingleTransformExpr(source: TokenSyntax, transform: ExprSyntax?) -> CodeBlockItemSyntax {
            return if let transform {
                "try \(GenerationItems.transformFunctionName)(\(source), \(transform))"
            } else {
                "\(source)"
            }
        }


        static func decodeNestedContainerStmt(parentContainer: CodingContainerName, pathElement: String) -> CodeBlockItemSyntax {
            let container = parentContainer.childContainer(with: pathElement)
            return """
                let \(container.varName) = try \(parentContainer.varName).nestedContainer(
                    keyedBy: \(container.codingKeysName).self, 
                    forKey: .k\(raw: pathElement)
                )
                """
        }


        static func decodeNestedContainerStmt(parentUnkeyedContainer: CodingContainerName) -> CodeBlockItemSyntax {
            let container = parentUnkeyedContainer.childContainer(with: "root")
            return """
                let \(container.varName) = try \(parentUnkeyedContainer.varName).nestedContainer(
                    keyedBy: \(container.codingKeysName).self
                )
                """
        }


        static func decodeNestedContainerStmt(container: CodingContainerName) -> CodeBlockItemSyntax {
            return "let \(container.varName) = try decoder.container(keyedBy: \(container.codingKeysName).self)"
        }


        static func decodeNestedUnkeyedContainerStmt(
            parentContainer: CodingContainerName,
            pathElement: String
        ) -> CodeBlockItemSyntax {
            let container = parentContainer.childContainer(with: pathElement)
            return """
                var \(container.varName) = try \(parentContainer.varName).nestedUnkeyedContainer(
                    forKey: .k\(raw: pathElement)
                )
                """
        }


        static func decodeExpr(
            container: CodingContainerName,
            pathElement: String,
            type: ExprSyntax
        ) -> CodeBlockItemSyntax {
            return "try \(container.varName).decode(\(type), forKey: .k\(raw: pathElement))"
        }


        static func decodeExpr(
            unkeyedContainer: CodingContainerName,
            type: ExprSyntax
        ) -> CodeBlockItemSyntax {
            return "try \(unkeyedContainer.varName).decode(\(type))"
        }


        static func encodeNestedContainerStmt(
            container: CodingContainerName
        ) -> CodeBlockItemSyntax {
            return "var \(container.varName) = encoder.container(keyedBy: \(container.codingKeysName).self)"
        }


        static func encodeNestedContainerStmt(
            parentContainer: CodingContainerName,
            pathElement: String
        ) -> CodeBlockItemSyntax {
            let container = parentContainer.childContainer(with: pathElement)
            return """
                var \(container.varName) = \(parentContainer.varName).nestedContainer(
                    keyedBy: \(container.codingKeysName).self,
                    forKey: .k\(raw: pathElement)
                )
                """
        }


        static func encodeNestedContainerStmt(
            parentUnkeyedContainer: CodingContainerName
        ) -> CodeBlockItemSyntax {
            let container = parentUnkeyedContainer.childContainer(with: "root")
            return """
                var \(container.varName) = \(parentUnkeyedContainer.varName).nestedContainer(
                    keyedBy: \(container.codingKeysName).self
                )
                """
        }


        static func encodeNestedUnkeyedContainerStmt(
            parentContainer: CodingContainerName,
            pathElement: String
        ) -> CodeBlockItemSyntax {
            let container = parentContainer.childContainer(with: pathElement)
            return """
                var \(container.varName) = \(parentContainer.varName).nestedUnkeyedContainer(
                    forKey: .k\(raw: pathElement)
                )
                """
        }


        static func encodeExpr(
            container: CodingContainerName,
            pathElement: String,
            value: ExprSyntax
        ) -> CodeBlockItemSyntax {
            return "try \(container.varName).encode(\(value), forKey: .k\(raw: pathElement))"
        }


        static func encodeExpr(
            unkeyedContainer: CodingContainerName,
            value: ExprSyntax
        ) -> CodeBlockItemSyntax {
            return "try \(unkeyedContainer.varName).encode(\(value))"
        }

    }


    struct CodingContainerName: Sendable, Equatable {

        let name: TokenSyntax

        var varName: TokenSyntax { GenerationItems.containerVarName(of: name) }
        var codingKeysName: TokenSyntax { GenerationItems.codingKeysName(of: name) }
        

        func childContainer(with pathElement: String) -> CodingContainerName {
            .init(name: GenerationItems.containerName(byAppending: pathElement, to: name))
        }

    }

}



extension CodableMacro.CodingContainerName: ExpressibleByStringLiteral {

    init(stringLiteral value: StringLiteralType) {
        self.name = .init(stringLiteral: value)
    }

}