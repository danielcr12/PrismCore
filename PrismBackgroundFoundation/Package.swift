// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "PrismBackgroundFoundation",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PrismBackgroundFoundation",
            targets: ["PrismBackgroundFoundation"]
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
            name: "PrismBackgroundFoundation",
            dependencies: [
                .product(name: "OKLCHKit", package: "OKLCHKit"),
            ]
        ),
        .testTarget(
            name: "PrismBackgroundFoundationTests",
            dependencies: ["PrismBackgroundFoundation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
