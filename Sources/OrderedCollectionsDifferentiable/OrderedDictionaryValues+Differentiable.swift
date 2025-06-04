#if canImport(_Differentiation)

import _Differentiation

extension OrderedDictionary.Values: @retroactive Differentiable where Value: Differentiable {
    public typealias TangentVector = Array<Value.TangentVector>.TangentVector

    public mutating func move(by offset: OrderedDictionary<Key, Value>.Values.TangentVector) {
        for (i, j) in zip(self.indices, offset.base.indices) {
            self[i].move(by: offset.base[j])
        }
    }
}

extension OrderedDictionary.Values where Value: Differentiable {
    /// Defines a derivative for `OrderedDictionary`s subscript getter enabling calls like `var value = dictionary[key]` to be
    /// differentiable
    @inlinable
    @derivative(of: subscript(_:))
    func _vjpSubscript(position: Int) -> (
        value: Value,
        pullback: (Value.TangentVector) -> OrderedDictionary<Key, Value>.Values.TangentVector
    ) {
        let count = self.count
        return (
            value: self[position],
            pullback: { tangentVector in
                var vector = Array<Value.TangentVector>.TangentVector(.init(repeating: .zero, count: count))
                vector.base[position] = tangentVector
                return vector
            }
        )
    }

    @derivative(of: elements)
    @inlinable
    func _vjpElements() -> (
        value: Array<Value>,
        pullback: (Array<Value>.TangentVector) -> OrderedDictionary.Values.TangentVector
    ) {
        (
            value: self.elements,
            pullback: { v in v }
        )
    }
}

#endif
