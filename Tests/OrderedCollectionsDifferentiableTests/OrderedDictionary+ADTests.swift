#if canImport(_Differentiation)

import OrderedCollectionsDifferentiable
import Testing

@Suite("OrderedDictionary+AD")
struct OrderedDictionaryADTests {
    // MARK: Getter

    @Test
    func testSubscriptGetGradient() throws {
        let dictionary: OrderedDictionary<String, Double> = ["a": 3, "b": 7]

        let aMultiplier: Double = 13
        let bMultiplier: Double = 17

        @differentiable(reverse)
        func readFromDictionary(d: OrderedDictionary<String, Double>) -> Double {
            // note that we cannot use #require here as this function cannot throw (due to current compiler constraints wrt differentiation)
            // swift-format-ignore: NeverForceUnwrap
            let a = d[ad: "a"]! * aMultiplier
            let b = d[ad: "b"]! * bMultiplier
            return a + b
        }

        let vwg = valueWithGradient(at: dictionary, of: readFromDictionary)

        #expect(vwg.value == 3 * aMultiplier + 7 * bMultiplier)
        #expect(vwg.gradient == ["a": aMultiplier, "b": bMultiplier])
    }

    @Test
    func testSubscriptGetSameKeyTwiceAccumulates() throws {
        let dictionary: OrderedDictionary<String, Double> = ["a": 1]

        @differentiable(reverse)
        func readTwice(d: OrderedDictionary<String, Double>) -> Double {
            // swift-format-ignore: NeverForceUnwrap
            d[ad: "a"]! * 2 + d[ad: "a"]! * 3
        }

        let vwg = valueWithGradient(at: dictionary, of: readTwice)

        #expect(vwg.value == 5)
        #expect(vwg.gradient == ["a": 5])
    }

    // MARK: Setter

    @Test
    func testSubscriptSetWriteThenReadAllKeys() throws {
        let dictionary: OrderedDictionary<String, Double> = ["a": 1, "b": 1]

        let aMultiplier: Double = 13
        let bMultiplier: Double = 17

        @differentiable(reverse)
        func writeAndRead(d: OrderedDictionary<String, Double>, newA: Double, newB: Double) -> Double {
            var d = d
            d[ad: "a"] = newA
            d[ad: "b"] = newB
            // swift-format-ignore: NeverForceUnwrap
            return d[ad: "a"]! * aMultiplier + d[ad: "b"]! * bMultiplier
        }

        let vwg = valueWithGradient(at: dictionary, 3.0, 7.0, of: writeAndRead)

        #expect(vwg.value == 3 * aMultiplier + 7 * bMultiplier)
        // Both keys of the input are overwritten, so the input's gradient is zero;
        // the gradients flow to newA/newB instead.
        #expect(vwg.gradient.0 == [:])
        #expect(vwg.gradient.1 == aMultiplier)
        #expect(vwg.gradient.2 == bMultiplier)
    }

    @Test
    func testSubscriptSetWriteOneKeyReadAnother() throws {
        // Regression test: write to "a", then read a *different* existing key "b".
        // The gradient w.r.t. the input dictionary must preserve d["b"], and newA
        // must receive zero gradient (it does not influence the output).
        let dictionary: OrderedDictionary<String, Double> = ["a": 1, "b": 1]

        @differentiable(reverse)
        func writeAReadB(d: OrderedDictionary<String, Double>, newA: Double) -> Double {
            var d = d
            d[ad: "a"] = newA
            // swift-format-ignore: NeverForceUnwrap
            return d[ad: "b"]! * 2
        }

        let vwg = valueWithGradient(at: dictionary, 5.0, of: writeAReadB)

        #expect(vwg.value == 2)
        #expect(vwg.gradient.0 == ["b": 2])
        #expect(vwg.gradient.1 == 0)
    }

    // Writing to a key that isn't present in the base dictionary would previously make the
    // setter pullback insert `key: .zero` into the base tangent (it zeroes the overwritten
    // slot in place). That stray zero entry would survive into the gradient, so applying it
    // back with `move(by:)` would previously hit `fatalMissingComponent` because the primal
    // dictionary had no such key.
    //
    // Setting the slot to `nil` instead of `.zero` in `_vjpSubscriptSet` drops the entry
    // (a missing key is definitionally zero) and this now no longer crashes.
    @Test
    func testWritingNewKeyLeavesNoStrayZero() {
        @differentiable(reverse)
        func insertNewKey(dict: OrderedDictionary<String, Double>) -> OrderedDictionary<String, Double> {
            var copy = dict
            copy[ad: "new"] = 5.0 // "new" is absent from the base dictionary
            return copy
        }

        var params: OrderedDictionary<String, Double> = ["a": 1.0]
        let vwpb = valueWithPullback(at: params, of: insertNewKey)

        let gradient = vwpb.pullback(["a": 1.0, "new": 1.0])

        // "new" was overwritten, so it is dropped from the base gradient rather than left as a stray zero.
        #expect(gradient == ["a": 1.0])

        // `params` has no "new" key; `move(by:)` must not trip `fatalMissingComponent`.
        params.move(by: gradient)
    }
}

#endif
