// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrismCore",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "PrismCore",
            targets: ["PrismCore"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/danielcr12/PrismBackgroundFoundation.git",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "PrismCore",
            dependencies: [
                .product(
                    name: "PrismBackgroundFoundation",
                    package: "PrismBackgroundFoundation"
                ),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "PrismCoreTests",
            dependencies: ["PrismCore"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
