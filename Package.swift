// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrismCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "PrismCore",
            targets: ["PrismCore"]
        ),
        .library(
            name: "PrismCoreBackgrounds",
            targets: ["PrismCoreBackgrounds"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/danielcr12/OKLCHKit.git",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "PrismCoreBackgrounds",
            dependencies: [
                .product(name: "OKLCHKit", package: "OKLCHKit"),
            ]
        ),
        .target(
            name: "PrismCore",
            dependencies: [
                "PrismCoreBackgrounds",
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
        .testTarget(
            name: "PrismCoreBackgroundsTests",
            dependencies: ["PrismCoreBackgrounds"]
        ),
    ]
)
