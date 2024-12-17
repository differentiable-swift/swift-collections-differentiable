#if canImport(_Differentiation)

import _Differentiation

extension OrderedDictionary: @retroactive Differentiable where Value: Differentiable {
    public typealias TangentVector = OrderedDictionary<Key, Value.TangentVector>

    public mutating func move(by direction: TangentVector) {
        for (componentKey, componentDirection) in direction {
            func fatalMissingComponent() -> Value {
                preconditionFailure("missing component \(componentKey) in moved OrderedDictionary")
            }
            self[componentKey, default: fatalMissingComponent()].move(by: componentDirection)
        }
    }
}

/// Implements the `AdditiveArithmetic` requirements.
extension OrderedDictionary: @retroactive AdditiveArithmetic where Value: AdditiveArithmetic {
    public static func + (_ lhs: Self, _ rhs: Self) -> Self {
        lhs.merging(rhs, uniquingKeysWith: +)
    }

    public static func - (_ lhs: Self, _ rhs: Self) -> Self {
        lhs.merging(rhs.mapValues { .zero - $0 }, uniquingKeysWith: +)
    }

    public static var zero: Self { [:] }
}

extension OrderedDictionary where Value: Differentiable {
    /// Defines a derivative for `OrderedDictionary`s subscript getter enabling calls like `var value = dictionary[key]` to be
    /// differentiable
    @inlinable
    @derivative(of: subscript(_:))
    func _vjpSubscript(key: Key)
        -> (value: Value?, pullback: (Optional<Value>.TangentVector) -> OrderedDictionary<Key, Value>.TangentVector)
    {
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
}

// TODO: make `OrderedDictionary.Values` and `OrderedDictionary.Elements` differentiable

#endif
