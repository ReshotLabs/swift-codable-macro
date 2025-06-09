

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