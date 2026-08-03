#if canImport(_Differentiation)

import _Differentiation

extension OrderedDictionary: @retroactive Differentiable where Value: Differentiable {
    public typealias TangentVector = OrderedDictionary<Key, Value.TangentVector>

    @inlinable
    public mutating func move(by offset: TangentVector) {
        for (key, tangentValue) in offset {
            func fatalMissingComponent() -> Value {
                preconditionFailure("missing entry for key \(key) in moved OrderedDictionary")
            }
            self[key, default: fatalMissingComponent()].move(by: tangentValue)
        }
    }
}

/// Implements the `AdditiveArithmetic` requirements.
extension OrderedDictionary: @retroactive AdditiveArithmetic where Value: AdditiveArithmetic {
    @inlinable
    public static func + (_ lhs: Self, _ rhs: Self) -> Self {
        lhs.merging(rhs, uniquingKeysWith: +)
    }

    @inlinable
    public static func - (_ lhs: Self, _ rhs: Self) -> Self {
        lhs.merging(rhs.mapValues { .zero - $0 }, uniquingKeysWith: +)
    }

    @inlinable
    public static var zero: Self { [:] }
}

extension OrderedDictionary where Value: Differentiable {
    /// Defines a derivative for `OrderedDictionary`s subscript getter enabling calls like `var value = dictionary[key]` to be
    /// differentiable
    @inlinable
    @derivative(of: subscript(_:))
    func _vjpSubscript(key: Key) -> (
        value: Value?,
        pullback: (Optional<Value>.TangentVector) -> OrderedDictionary<Key, Value>.TangentVector
    ) {
        let keys = self.keys
        // When adding two dictionaries, nil values are equivalent to zeroes, so there is no need to manually zero-out
        // every key's value. Instead, it is faster to create a dictionary with the single non-zero entry.
        // for ordered dictionaries however we can't because the keys will be added in reverse order so the tangentvector's key order will
        // be different from the original
        return (
            value: self[key],
            pullback: { tangentVector in
                if let value = tangentVector.value {
                    var zeroTangentVector = OrderedDictionary<Key, Value.TangentVector>(
                        uniqueKeys: keys,
                        values: repeatElement(.zero, count: keys.count)
                    )
                    zeroTangentVector[key] = value
                    return zeroTangentVector
                }
                else {
                    return .zero
                }
            }
        )
    }

    @derivative(of: values)
    @inlinable
    @inline(__always)
    public func _vjpValues() -> (value: Values, pullback: (Values.TangentVector) -> OrderedDictionary<Key, Value>.TangentVector) {
        let keys = self.keys
        return (
            value: self.values,
            pullback: { v in
                var dict = OrderedDictionary<Key, Value>.TangentVector()
                dict.reserveCapacity(keys.count)
                for (key, tangentValue) in zip(keys, v.base) {
                    dict[key] = tangentValue
                }
                return dict
            }
        )
    }
}

// TODO: make `OrderedDictionary.Elements` differentiable

#endif
