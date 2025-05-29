

extension Optional {

    func orElse<E: Error>(_ defaultValueGenerator: () throws(E) -> Wrapped) throws(E) -> Wrapped {
        if self != nil {
            return self.unsafelyUnwrapped
        } else {
            return try defaultValueGenerator()
        }
    }

}