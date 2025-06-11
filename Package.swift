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
        .package(url: "https://github.com/adaptyteam/AdaptySDK-iOS", exact: "3.8.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.6.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.27.0"),
    ],
    targets: [
        .target(
            name: "IAPKit",
            dependencies: [
                .product(name: "Adapty", package: "AdaptySDK-iOS"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(
            name: "IAPKitTests",
            dependencies: ["IAPKit"]
        ),
    ]
)
