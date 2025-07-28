

extension Optional {

    func orElse<E: Error>(_ defaultValueGenerator: () throws(E) -> Wrapped) throws(E) -> Wrapped {
        if self != nil {
            return self.unsafelyUnwrapped
        } else {
            return try defaultValueGenerator()
        }
    }


    func ifPresent(_ action: (Wrapped) -> Void) -> Self {
        if let value = self {
            action(value)
        }
        return self
    }

    
    func ifMissing(_ action: () -> Void) -> Self {
        if self == nil {
            action()
        }
        return self
    }

}



extension Collection {

    var isNotEmpty: Bool {
        !isEmpty
    }

}


extension RangeReplaceableCollection {

    func appending(contentsOf newElements: some RangeReplaceableCollection<Element>) -> Self {
        return self + newElements
    }

    func appending(_ newElement: Element) -> Self {
        var copy = self
        copy.append(newElement)
        return copy
    }

}


extension String {
    
    /// Convert camelCase string to snake_case
    func convertToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        
        let result = self
            .replacingOccurrences(of: acronymPattern, with: "$1_$2", options: .regularExpression)
            .replacingOccurrences(of: normalPattern, with: "$1_$2", options: .regularExpression)
            .lowercased()
        
        return result
    }
    
}