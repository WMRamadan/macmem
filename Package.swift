// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "macmem",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacMemKit",
            targets: ["MacMemKit"]
        ),
        .executable(
            name: "macmem",
            targets: ["macmem"]
        ),
    ],
    targets: [
        .target(
            name: "MacMemKit",
            dependencies: [],
            path: "Sources/MacMemKit"
        ),
        .executableTarget(
            name: "macmem",
            dependencies: ["MacMemKit"],
            path: "Sources/macmem"
        ),
        .testTarget(
            name: "MacMemTests",
            dependencies: ["MacMemKit"],
            path: "Tests/MacMemTests"
        ),
    ]
)

