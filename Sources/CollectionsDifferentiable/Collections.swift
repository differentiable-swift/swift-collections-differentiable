// A module that re-exports Swift Collections API and the Differentiable extensions to the Swift Collections API
@_exported import Collections
// Swift Collection modules with Differentiable extensions
@_exported import OrderedCollectionsDifferentiable

// Export the differentiation module since we're trying to use its api
#if canImport(_Differentiation)
@_exported import _Differentiation
#endif
