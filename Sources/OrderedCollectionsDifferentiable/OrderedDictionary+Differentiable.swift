#if canImport(_Differentiation)

import _Differentiation

/// This file makes `OrderedDictionary` differentiable.
extension OrderedDictionary: Differentiable where Value: Differentiable {
    public typealias TangentVector = OrderedDictionary<Key, Value.TangentVector>
    public mutating func move(by direction: TangentVector) {
        for (componentKey, componentDirection) in direction {
            func fatalMissingComponent() -> Value {
                preconditionFailure("missing component \(componentKey) in moved Dictionary")
            }
            self[componentKey, default: fatalMissingComponent()].move(by: componentDirection)
        }
    }

    public var zeroTangentVectorInitializer: () -> TangentVector {
        let listOfKeys = keys // capturing only what's needed, not the entire self, in order to not waste memory
        func initializer() -> Self.TangentVector {
            return listOfKeys.reduce(into: OrderedDictionary<Key, Value.TangentVector>()) { $0[$1] = Value.TangentVector.zero }
        }
        return initializer
    }
}

/// Implements the `AdditiveArithmetic` requirements.
extension OrderedDictionary: AdditiveArithmetic where Value: AdditiveArithmetic {
    public static func + (_ lhs: Self, _ rhs: Self) -> Self {
        lhs.merging(rhs, uniquingKeysWith: +)
    }

    public static func - (_ lhs: Self, _ rhs: Self) -> Self {
        lhs.merging(rhs.mapValues { .zero - $0 }, uniquingKeysWith: +)
    }

    public static var zero: Self { [:] }
}

public extension OrderedDictionary {
    /// non-differentiable version of getValuesArray; differentiable version is defined
    /// in the appropriate extension
    @inlinable
    func getValuesArray() -> Array<Value> {
        return Array<Value>(self.values)
    }
}

// attempt to make builtin subscript differentiable:
// https://bugs.swift.org/browse/TF-1193
// https://github.com/apple/swift/pull/32614/
// https://github.com/borglab/SwiftFusion/blob/main/Sources/SwiftFusion/Core/Dictionary+Differentiable.swift

extension OrderedDictionary where Value: Differentiable {
    // get
    // swiftformat:disable:next typeSugar
    // periphery:ignore
    @usableFromInline
    @derivative(of: subscript(_:))
    func vjpSubscriptGet(key: Key)
        -> (value: Value?, pullback: (Optional<Value>.TangentVector) -> OrderedDictionary<Key, Value>.TangentVector)
    {
        // When adding two dictionaries, nil values are equivalent to zeroes, so there is no need to manually zero-out
        // every key's value. Instead, it is faster to create a dictionary with the single non-zero entry.
        return (self[key], { tangentVector in
            if let value = tangentVector.value {
                return [key: value]
            }
            else {
                return .zero
            }
        })
    }

    /// differentiable version of the function that allows gathering
    /// all values of the dictionary as an array
    @differentiable(reverse)
    public func getValuesArray() -> [Value] {
        var values = [Value]()
        for key in withoutDerivative(at: keys) {
            values.append(self[key]!) // swiftlint:disable:this force_unwrapping
        }
        return values
    }
}




// create a differentiable element (key value pair) getter
// this is a workaround for `OrderedDictionary.Elements` not being differentiable for now
public extension OrderedDictionary where Value: Differentiable {
    /// differentiable work around to be able to "differentiably" read from the elements collection
    @differentiable(reverse)
    func getElement(at offset: Int) -> TmpKeyValuePair {
        let element = self.elements[offset]
        return TmpKeyValuePair(key: element.key, value: element.value)
    }

    /// derivative of `getElement` function.
    @derivative(of: getElement)
    func vjpGetElement(at offset: Int) -> (value: TmpKeyValuePair, pullback: (TmpKeyValuePair.TangentVector) -> Self.TangentVector) {
        let element = self.elements[offset]
        let keyValuePair = TmpKeyValuePair(key: element.key, value: element.value)
        let key = element.key
        return (keyValuePair, { tangentVector in
            [key: tangentVector.value]
        })
    }

    struct TmpKeyValuePair: Differentiable {
        @noDerivative
        public var key: Key
        public var value: Value
    }
}

#endif

