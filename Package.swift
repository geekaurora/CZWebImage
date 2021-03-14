// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CZWebImage",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CZWebImage",
            type: .dynamic,
            targets: ["CZWebImage"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/geekaurora/CZUtils.git", from: "3.2.7"),
        .package(url: "https://github.com/geekaurora/CZNetworking.git", from: "3.2.2"),
        .package(url: "https://github.com/geekaurora/CZHttpFileCache.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CZWebImage",
            dependencies: ["CZUtils", "CZNetworking", "CZHttpFileCache"]),
    ]
)
