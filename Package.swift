// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SemanticVersioning",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "SemanticVersioning", targets: ["SemanticVersioning"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SemanticVersioning",
            dependencies: [],
            path: "Source"),
        .testTarget(
            name: "SemanticVersioningTests",
            dependencies: ["SemanticVersioning"],
            path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)
