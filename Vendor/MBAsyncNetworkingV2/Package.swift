// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MBAsyncNetworkingV2",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .macOS(.v11), .watchOS(.v7)],
    products: [
        .library(
            name: "MBAsyncNetworkingV2",
            targets: ["MBAsyncNetworkingV2"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mobven/MobKitCore.git", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "MBAsyncNetworkingV2",
            dependencies: ["MobKitCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "MBAsyncNetworkingV2Tests",
            dependencies: ["MBAsyncNetworkingV2"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
