// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AttentionBar",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "AttentionBarKit", targets: ["AttentionBarKit"]),
        .executable(name: "AttentionBar", targets: ["AttentionBarApp"]),
    ],
    targets: [
        .target(name: "AttentionBarKit"),
        .executableTarget(
            name: "AttentionBarApp",
            dependencies: ["AttentionBarKit"]
        ),
        .testTarget(
            name: "AttentionBarKitTests",
            dependencies: ["AttentionBarKit"]
        ),
    ]
)
