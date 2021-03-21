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
    .package(url: "https://github.com/geekaurora/CZUtils.git", from: "3.2.7"),
    .package(url: "https://github.com/geekaurora/CZNetworking.git", from: "3.2.2"),
    .package(url: "https://github.com/geekaurora/CZHttpFile.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "CZWebImage",
      dependencies: ["CZUtils", "CZNetworking", "CZHttpFile"]),
  ]
)
