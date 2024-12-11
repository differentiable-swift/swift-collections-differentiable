#if canImport(_Differentiation)

import _Differentiation

#endif

extension OrderedDictionary {
    /// A Differentiable alternative to `OrderedDictionary.subscript.modify`
    /// Differentiation does not yet support `OrderedDictionary.subscript.modify` because it is a coroutine.
    #if canImport(_Differentiation)
    @differentiable(reverse where Value: Differentiable)
    #endif
    @inlinable
    public mutating func update(at key: Key, with newValue: Value) {
        self[key] = newValue
    }
}

#if canImport(_Differentiation)

extension OrderedDictionary where Value: Differentiable {
    /// This function defines a derivative for AutoDiff to use when update() is called. It's not meant to be called directly in most
    /// situations.
    ///
    /// - Parameters:
    ///     - key: The key to update the value at.
    ///     - newValue: The value to write.
    /// - Returns: The object, plus the pullback.
    @derivative(of: update(at:with:))
    @inlinable
    public mutating func _vjpUpdate(
        at key: Key,
        with newValue: Value
    ) -> (value: Void, pullback: (inout TangentVector) -> (Value.TangentVector)) {
        update(at: key, with: newValue)

        let forwardCount = count
        let forwardKeys = keys // may be heavy to capture all of these, not sure how to do without them though

        return ((), { tangentVector in
            // manual zero tangent initialization
            if tangentVector.count < forwardCount {
                tangentVector = Self.TangentVector()
                forwardKeys.forEach { tangentVector[$0] = .zero }
            }

            if let dElement = tangentVector[key] {
                tangentVector[key] = .zero
                return dElement
            }
            else { // should this fail?
                tangentVector[key] = .zero
                return .zero
            }
        })
    }
}

#endif
