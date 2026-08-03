// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-collections-differentiable",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0"),
    ],
    products: [
        .library(
            name: "CollectionsDifferentiable",
            targets: ["CollectionsDifferentiable"]
        ),
        .library(
            name: "OrderedCollectionsDifferentiable",
            targets: ["OrderedCollectionsDifferentiable"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/differentiable-swift/swift-differentiation.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "CollectionsDifferentiable",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                "OrderedCollectionsDifferentiable",
            ]
        ),
        .target(
            name: "OrderedCollectionsDifferentiable",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Differentiation", package: "swift-differentiation"),
            ]
        ),
        .testTarget(
            name: "OrderedCollectionsDifferentiableTests",
            dependencies: [
                "OrderedCollectionsDifferentiable",
            ]
        ),
    ]
)
