// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-collections-differentiable",
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
    ],
    targets: [
        .target(
            name: "CollectionsDifferentiable",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                "OrderedCollectionsDifferentiable"
            ]
        ),
        .target(
            name: "OrderedCollectionsDifferentiable",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
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
