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
    targets: [
        .target(
            name: "InjiVcRenderer"),
        .testTarget(
            name: "InjiVcRendererTests",
            dependencies: ["InjiVcRenderer"]),
    ]
)
