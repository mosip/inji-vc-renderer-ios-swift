// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InjiVcRenderer",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "InjiVcRenderer",
            targets: ["InjiVcRenderer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mosip/pixelpass-ios-swift.git", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "InjiVcRenderer",
            dependencies: [
                    .product(name: "pixelpass", package: "pixelpass-ios-swift"),
                ]),
        .testTarget(
            name: "InjiVcRendererTests",
            dependencies: ["InjiVcRenderer"]),
    ]
)
