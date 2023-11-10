// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Typhoon",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "Typhoon", targets: ["Typhoon"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Typhoon", dependencies: []),
        .testTarget(name: "TyphoonTests", dependencies: ["Typhoon"]),
    ]
)
