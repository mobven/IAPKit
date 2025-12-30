// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IAPKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "IAPKit",
            targets: ["IAPKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/adaptyteam/AdaptySDK-iOS", exact: "3.11.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.6.0"),
        .package(url: "https://github.com/mobven/MobKitCore.git", from: "1.0.1"),
        .package(url: "https://github.com/mobven/MBAsyncNetworking.git", from: "0.1.3"),
    ],
    targets: [
        .target(
            name: "IAPKit",
            dependencies: [
                .product(name: "Adapty", package: "AdaptySDK-iOS"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "MobKitCore", package: "MobKitCore"),
                .product(name: "MBAsyncNetworking", package: "MBAsyncNetworking")
            ]
        ),
        .testTarget(
            name: "IAPKitTests",
            dependencies: ["IAPKit"]
        ),
    ]
)
