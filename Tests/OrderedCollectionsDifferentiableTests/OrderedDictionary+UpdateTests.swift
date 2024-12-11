#if canImport(_Differentiation)

import OrderedCollectionsDifferentiable
import Testing

@Suite("OrderedDictionary+Update")
struct OrderedDictionaryUpdateTests {
    @Test
    func testUpdateWithValue() throws {
        let dictionary: OrderedDictionary<String, Double> = ["a": 1, "b": 1]

        let aMultiplier: Double = 13
        let bMultiplier: Double = 17

        func writeAndReadFromDictionary(dict: OrderedDictionary<String, Double>, newA: Double, newB: Double) -> Double {
            var dict = dict
            dict.update(at: "a", with: newA)
            dict.update(at: "b", with: newB)

            // note that we cannot use #require here as this function cannot throw (due to current compiler constraints wrt differentiation)
            // swift-format-ignore: NeverForceUnwrap
            let a = dict["a"]! * aMultiplier
            let b = dict["b"]! * bMultiplier
            return a + b
        }

        let newA: Double = 3
        let newB: Double = 7

        let valAndGrad = valueWithGradient(at: dictionary, newA, newB, of: writeAndReadFromDictionary)
        #expect(valAndGrad.value == newA * aMultiplier + newB * bMultiplier)
        #expect(valAndGrad.gradient == (["a": 0, "b": 0], aMultiplier, bMultiplier))
    }
}

#endif
