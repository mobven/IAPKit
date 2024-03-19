// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IAPKit",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "IAPKit",
            targets: ["IAPKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/adaptyteam/AdaptySDK-iOS", exact: "2.9.3"),
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.6.0"),
    ],
    targets: [
        .target(
            name: "IAPKit",
            dependencies: [
                .product(name: "Adapty", package: "AdaptySDK-iOS"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
            ]
        ),
        .testTarget(
            name: "IAPKitTests",
            dependencies: ["IAPKit"]
        ),
    ]
)
