#if canImport(_Differentiation)

import OrderedCollectionsDifferentiable
import Testing

@Suite("Dictionary+Differentiation")
struct DictionaryDifferentiationTests {
    @Test
    func testSubscriptGet() throws {
        let dictionary: OrderedDictionary<String, Double> = ["a": 3, "b": 7]

        let aMultiplier: Double = 13
        let bMultiplier: Double = 17

        func readFromDictionary(d: OrderedDictionary<String, Double>) -> Double {
            // note that we cannot use #require here as this function cannot throw (due to current compiler constraints wrt differentiation)
            // swift-format-ignore: NeverForceUnwrap
            let a = d["a"]! * aMultiplier
            let b = d["b"]! * bMultiplier
            return a + b
        }

        let vwg = valueWithGradient(at: dictionary, of: readFromDictionary)

        #expect(vwg.value == 3 * aMultiplier + 7 * bMultiplier)
        #expect(vwg.gradient == ["a": aMultiplier, "b": bMultiplier])
    }

    @Test
    func testOrderedDictionaryReadAndCombineValues() {
        @differentiable(reverse)
        func testFunction(newValues: OrderedDictionary<String, Double>) -> Double {
            // note that we cannot use #require here as this function cannot throw (due to current compiler constraints wrt differentiation)
            // swift-format-ignore: NeverForceUnwrap
            1.0 * newValues["s1"]! + 2.0 * newValues["s2"]! + 3.0 * newValues["s3"]!
        }

        let vwg = valueWithGradient(
            at: ["s1": 10.0, "s2": 20.0, "s3": 30.0],
            of: testFunction
        )

        #expect(vwg.value == 140.0)
        #expect(vwg.gradient == ["s1": 1.0, "s2": 2.0, "s3": 3.0])
    }
    
    
    
    @Test
    func testOrderedDictionaryInoutWriteMethod() {
        @differentiable(reverse)
        func combineByReplacingDictionaryValues(of mainDict: inout OrderedDictionary<String, Double>, with otherDict: OrderedDictionary<String, Double>) {
            for key in withoutDerivative(at: otherDict.keys) {
                // note that we cannot use #require here as this function cannot throw (due to current compiler constraints wrt differentiation)
                // swift-format-ignore: NeverForceUnwrap
                let otherValue = otherDict[key]!
                mainDict.update(at: key, with: otherValue)
            }
        }

        @differentiable(reverse)
        func inoutWrapper(dictionary: OrderedDictionary<String, Double>, otherDictionary: OrderedDictionary<String, Double>) -> OrderedDictionary<String, Double> {
            // we wrap the `combineByReplacingDictionaryValues`
            var mainCopy = dictionary
            combineByReplacingDictionaryValues(of: &mainCopy, with: otherDictionary)
            return mainCopy
        }

        let vwpb = valueWithPullback(
            at: ["s1": 10.0, "s2": 20.0, "s3": 30.0],
            ["s1": 2.0],  //, "s2": nil, "s3": nil],
            of: inoutWrapper
        )

        #expect(vwpb.value == ["s1": 2.0, "s2": 20.0, "s3": 30.0])
        // we need to provide a full tangentvector to the pullback hence the keys with zero entries.
        #expect(vwpb.pullback(["s1": 1.0, "s2": 0.0, "s3": 0.0]) == (["s1": 0.0, "s2": 0.0, "s3": 0.0], ["s1": 1.0]))
        #expect(vwpb.pullback(["s1": 0.0, "s2": 1.0, "s3": 0.0]) == (["s1": 0.0, "s2": 1.0, "s3": 0.0], ["s1": 0.0]))
        #expect(vwpb.pullback(["s1": 0.0, "s2": 0.0, "s3": 1.0]) == (["s1": 0.0, "s2": 0.0, "s3": 1.0], ["s1": 0.0]))
    }

    @Test
    func testInoutWriteAndSumValues() {
        @differentiable(reverse)
        func combineByReplacingDictionaryValues(of mainDict: inout OrderedDictionary<String, Double>, with otherDict: OrderedDictionary<String, Double>) {
            for key in withoutDerivative(at: otherDict.keys) {
                // note that we cannot use #require here as this function cannot throw (due to current compiler constraints wrt differentiation)
                // swift-format-ignore: NeverForceUnwrap
                let otherValue = otherDict[key]!
                mainDict.update(at: key, with: otherValue)
            }
        }

        @differentiable(reverse)
        func sumValues(of dictionary: OrderedDictionary<String, Double>) -> Double {
            var sum: Double = 0.0
            for key in withoutDerivative(at: dictionary.keys) {
                // note that we cannot use #require here as this function cannot throw (due to current compiler constraints wrt differentiation)
                // swift-format-ignore: NeverForceUnwrap
                sum += dictionary[key]!
            }
            return sum
        }
        @differentiable(reverse,wrt: dictionary)

        func inoutWrapperAndSum(dictionary: OrderedDictionary<String, Double>, otherDictionary: OrderedDictionary<String, Double>) -> Double {
            var mainCopy = dictionary
            combineByReplacingDictionaryValues(of: &mainCopy, with: otherDictionary)
            return sumValues(of: mainCopy)
        }

        let vwg = valueWithGradient(
            at: ["s1": 10.0, "s2": 20.0, "s3": 30.0],
            ["s1": 2.0],  //, "s2": nil, "s3": nil],
            of: inoutWrapperAndSum
        )

        #expect(vwg.value == 52.0)
        #expect(vwg.gradient == (["s1": 0.0, "s2": 1.0, "s3": 1.0], ["s1": 1.0]))
    }
}

#endif
