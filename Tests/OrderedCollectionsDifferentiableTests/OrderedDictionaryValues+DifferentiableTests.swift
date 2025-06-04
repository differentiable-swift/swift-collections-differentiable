#if canImport(_Differentiation)

import OrderedCollectionsDifferentiable
import Testing

@Suite("OrderedDictionary.Values+Differentiable")
struct OrderedDictionaryValuesTests {
    @Test
    func dictionaryValuesMemberTest() {
        @differentiable(reverse)
        func values(dict: OrderedDictionary<String, Double>) -> OrderedDictionary<String, Double>.Values {
            dict.values
        }

        let dict: OrderedDictionary<String, Double> = ["a": 1.0, "b": 2.0]
        let vwpb = valueWithPullback(at: dict, of: values)

        #expect(vwpb.value == dict.values)
        let pullback = vwpb.pullback([0.0, 1.0])

        #expect(pullback == ["a": 0.0, "b": 1.0])
    }

    @Test
    func dictionaryValuesMemberElementsTest() {
        @differentiable(reverse)
        func elements(dict: OrderedDictionary<String, Double>) -> [Double] {
            dict.values.elements
        }

        let dict: OrderedDictionary<String, Double> = ["a": 1.0, "b": 2.0]
        let vwpb = valueWithPullback(at: dict, of: elements)

        #expect(vwpb.value == [1.0, 2.0])
        let pullback = vwpb.pullback([0.0, 1.0])

        #expect(pullback == ["a": 0.0, "b": 1.0])
    }

    @Test
    func dictionaryValuesMemberSubscriptTest() {
        @differentiable(reverse)
        func values(dict: OrderedDictionary<String, Double>, index: Int) -> Double {
            dict.values[index]
        }

        let dict: OrderedDictionary<String, Double> = ["a": 1.0, "b": 2.0]
        let vwpb = valueWithPullback(at: dict, of: { dict in
            values(dict: dict, index: 1)
        })

        #expect(vwpb.value == 2.0)
        let pullback = vwpb.pullback(1.0)

        #expect(pullback == ["a": 0.0, "b": 1.0])
    }
}

#endif
