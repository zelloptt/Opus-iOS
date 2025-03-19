// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Opus-iOS",
    products: [
      .library(name: "opus", targets: ["opus"]),
      .library(name: "ogg", targets: ["ogg"])
    ],
    targets: [
      .binaryTarget(name: "opus", path: "opus.xcframework"),
      .binaryTarget(name: "ogg", path: "ogg.xcframework")
    ]
)
