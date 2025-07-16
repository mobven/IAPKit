# IAPKit

A Swift package for handling In-App Purchases with support for both StoreKit and Adapty, featuring flexible logging capabilities.

## Overview

IAPKit provides a unified interface for managing in-app purchases across different platforms and services. It supports both StoreKit (Apple's native framework) and Adapty (third-party service) with automatic fallback mechanisms and configurable timeout handling.

## Features

- 🛒 **Unified IAP Interface**: Single API for both StoreKit and Adapty
- ⏱️ **Timeout Handling**: Configurable timeout with automatic fallback
- 🔄 **Purchase Restoration**: Easy purchase restoration functionality
- 👤 **User Management**: User identification and logout support
- 📊 **Flexible Logging**: Pluggable logging system with real-world logger support
- ✅ **Receipt Validation**: Built-in receipt verification

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/IAPKit", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Choose the version range

## Basic Usage

### 1. Initialize IAPKit

```swift
import IAPKit

// Configure IAPKit with Adapty
IAPKit.store.activate(adaptyApiKey: "your_adapty_api_key", paywallName: "your_paywall_name")

// Set timeout for Adapty (optional, default: 5 seconds)
IAPKit.store.adaptyTimeoutDuration = 3
```

### 2. Set Up Delegate

```swift
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        IAPKit.store.delegate = self
    }
}

extension ViewController: IAPKitDelegate {
    func iapKitDidBuy(product: IAPProduct, paywallId: String?) {
        // Handle successful purchase
        print("Successfully purchased: \(product.identifier)")
    }
    
    func iapKitDidFailToBuy(product: IAPProduct, withError error: Error) {
        // Handle purchase failure
        print("Purchase failed: \(error.localizedDescription)")
    }
    
    func iapKitGotError(_ error: Error, context: String?) {
        // Handle general errors
        print("IAPKit error: \(error.localizedDescription), context: \(context ?? "N/A")")
    }
}
```

### 3. Fetch and Display Products

```swift
// Fetch products (returns Observable for reactive programming)
let productsObservable = IAPKit.store.requestProducts()

// Or use completion handler
IAPKit.store.requestProducts { result in
    switch result {
    case .success(let products):
        // Display products in your UI
        self.displayProducts(products.products)
    case .failure(let error):
        // Handle error
        print("Failed to fetch products: \(error)")
    }
}
```

### 4. Purchase Products

```swift
// Purchase with completion handler
IAPKit.store.buyProduct(selectedProduct) { result in
    switch result {
    case .success(let subscription):
        // Handle successful purchase
        print("Purchase successful: \(subscription)")
    case .failure(let error):
        // Handle error
        print("Purchase failed: \(error)")
    }
}

// Or use reactive approach
let buyStateObservable = IAPKit.store.buyProduct(selectedProduct)
```

## Logging Integration

IAPKit provides a flexible logging system through the `SDKLoggable` protocol. You can integrate it with any logging framework.

### SDKLoggable Protocol

```swift
public protocol SDKLoggable: AnyObject {
    func logError(_ error: Error, context: String?)
}
```

### Integration with Firebase Crashlytics

```swift
import FirebaseCrashlytics

class CrashlyticsLogger: SDKLoggable {
    func logError(_ error: Error, context: String?) {
        // Log to Crashlytics with context
        let userInfo = context.map { ["context": $0] } ?? [:]
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
        
        // Also log as non-fatal for tracking
        Crashlytics.crashlytics().log("IAPKit Error - Context: \(context ?? "N/A")")
    }
}

// Set up the logger
IAPKit.store.logger = CrashlyticsLogger()
```

### Integration with OSLog (Apple's Unified Logging)

```swift
import os.log

class OSLogger: SDKLoggable {
    private let logger = Logger(subsystem: "com.yourapp.iapkit", category: "purchases")
    
    func logError(_ error: Error, context: String?) {
        logger.error("IAPKit Error: \(error.localizedDescription, privacy: .public) - Context: \(context ?? "N/A", privacy: .public)")
    }
}

// Set up the logger
IAPKit.store.logger = OSLogger()
```

### Integration with Custom Analytics

```swift
class AnalyticsLogger: SDKLoggable {
    func logError(_ error: Error, context: String?) {
        // Send to your analytics service
        Analytics.track("iap_error", properties: [
            "error": error.localizedDescription,
            "context": context ?? "unknown",
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code
        ])
        
        // Also log to console in debug mode
        #if DEBUG
        print("🔴 IAPKit Error: \(error.localizedDescription)")
        if let context = context {
            print("📍 Context: \(context)")
        }
        #endif
    }
}

// Set up the logger
IAPKit.store.logger = AnalyticsLogger()
```

### Composite Logger (Multiple Destinations)

```swift
class CompositeLogger: SDKLoggable {
    private let loggers: [SDKLoggable]
    
    init(loggers: [SDKLoggable]) {
        self.loggers = loggers
    }
    
    func logError(_ error: Error, context: String?) {
        // Log to all configured loggers
        loggers.forEach { logger in
            logger.logError(error, context: context)
        }
    }
}

// Set up multiple loggers
let compositeLogger = CompositeLogger(loggers: [
    CrashlyticsLogger(),
    OSLogger(),
    AnalyticsLogger()
])
IAPKit.store.logger = compositeLogger
```

## Advanced Usage

### User Management

```swift
// Identify user
IAPKit.store.identify("user_12345")

// Set external player ID (e.g., OneSignal)
IAPKit.store.setPlayerId("onesignal_player_id")

// Logout user
IAPKit.store.logout()
```

### Purchase Verification

```swift
// Check current subscription status
IAPKit.store.verify { isSubscribed in
    if isSubscribed {
        // User has active subscription
        self.showPremiumContent()
    } else {
        // Show paywall or free content
        self.showPaywall()
    }
}

// Fetch detailed profile information
IAPKit.store.fetchProfile { result in
    switch result {
    case .success(let profile):
        print("Subscribed: \(profile.isSubscribed)")
        print("Expires: \(profile.expireDate?.description ?? "N/A")")
    case .failure(let error):
        print("Profile fetch failed: \(error)")
    }
}
```

### Purchase Restoration

```swift
// Restore previous purchases
IAPKit.store.restorePurchases { result in
    switch result {
    case .success(let hasActiveSubscription):
        if hasActiveSubscription {
            // User has restored active purchases
            self.showPremiumContent()
        }
    case .failure(let error):
        // Handle restoration error
        print("Restore failed: \(error)")
    }
}
```

## Error Handling

IAPKit provides comprehensive error handling through the logging system. Common error contexts include:

- **"Adapty Activate"**: Issues during Adapty SDK initialization
- **Paywall Names**: Errors related to specific paywalls
- **"Cancelled payment by closing it"**: User cancelled the payment flow

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 14.0+

## Dependencies

- [Adapty SDK](https://github.com/adaptyteam/AdaptySDK-iOS) (3.8.0)
- [RxSwift](https://github.com/ReactiveX/RxSwift) (6.6.0+)

## License

[Add your license information here]

## Contributing

[Add contribution guidelines here]

## Support

[Add support contact information here] 