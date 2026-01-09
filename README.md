# IAPKit

A Swift package for handling In-App Purchases with support for StoreKit, Adapty, and RevenueCat, featuring flexible logging capabilities.

## Overview

IAPKit provides a unified interface for managing in-app purchases across different platforms and services. It supports StoreKit (Apple's native framework), Adapty, and RevenueCat with automatic fallback mechanisms and configurable timeout handling.

## What's New in v2

- 🪙 **Credits System**: Built-in credit/coin management with gift coins, subscription coins, and purchasable credit packages
- 🔐 **Backend Authentication**: Automatic device-based authentication with SDK key registration
- 🌐 **IAPKit API**: Server-side integration for receipt validation and credit management

## Features

- 🛒 **Unified IAP Interface**: Single API for StoreKit, Adapty, and RevenueCat
- 🎨 **Live Paywall Support**: RevenueCat remote paywall UI (iOS 15+)
- ⏱️ **Timeout Handling**: Configurable timeout with automatic fallback
- 🔄 **Purchase Restoration**: Easy purchase restoration functionality
- 👤 **User Management**: User identification and logout support
- 📊 **Flexible Logging**: Pluggable logging system with real-world logger support
- ✅ **Receipt Validation**: Built-in receipt verification
- 🪙 **Credits Management**: Manage user credits with spend, refresh, and claim features

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           YOUR APP                              │
│                                                                 │
│  IAPKit.store.activate(...)  .buy(...)  .verify(...)  .fetch() │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      IAPProductFetcher                          │
│                        (Coordinator)                            │
│                                                                 │
│  • Timeout management (default: 5s)                             │
│  • Primary/Fallback orchestration                               │
│  • Thread-safe state management                                 │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                ┌────────────────┴────────────────┐
                │                                 │
                ▼                                 ▼
┌───────────────────────────┐     ┌───────────────────────────┐
│     PRIMARY FETCHER       │     │    FALLBACK FETCHER       │
│   (ManagedIAPProvider)    │     │   (ProductFetchable)      │
│                           │     │                           │
│  ┌─────────────────────┐  │     │  ┌─────────────────────┐  │
│  │   AdaptyFetcher     │  │     │  │  StoreKitFetcher    │  │
│  │   • Paywall fetch   │  │     │  │  • Native StoreKit  │  │
│  │   • User identify   │  │     │  │  • SK1 / SK2        │  │
│  │   • Attribution     │  │     │  │  • Always available │  │
│  └─────────────────────┘  │     │  └─────────────────────┘  │
│          OR               │     │                           │
│  ┌─────────────────────┐  │     └───────────────────────────┘
│  │ RevenueCatFetcher   │  │
│  │ • Offerings         │  │
│  │ • Live Paywall UI   │  │
│  │ • User identify     │  │
│  └─────────────────────┘  │
└───────────────────────────┘
```

### Protocol Hierarchy

```
ProductFetchable (Base)
├── fetch(), buy(), restorePurchases(), fetchProfile()
│
├── StoreKitFetcher (implements only this)
│
└── ManagedIAPProvider (extends ProductFetchable)
    ├── activate(), logout(), identify()
    ├── setPlacement(), fetchPaywall()
    ├── setPlayerId(), setFirebaseId(), setAdjustDeviceId()
    │
    ├── AdaptyFetcher
    └── RevenueCatFetcher
            └── + PaywallProvidable (iOS 15+)
                  getPaywallView(), getPaywallViewController()
```

### Timeout Flow

When `fetch()` is called:
1. Primary fetcher starts fetching
2. Timeout timer starts (default: 5 seconds)
3. **If primary responds first** → Cancel timer, return primary results
4. **If timeout fires first** → Fallback to StoreKit, return StoreKit results

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mobven/IAPKit", from: "2.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Choose the version range

## Basic Usage

### 1. Initialize IAPKit

IAPKit supports two IAP providers: **Adapty** and **RevenueCat**. Choose one based on your preference.

#### Option A: Using Adapty

> **Important:** `sdkKey` is a required parameter unique to your application. Contact us to obtain your app-specific SDK key.

```swift
import IAPKit

// Configure IAPKit with Adapty
IAPKit.store.activate(
    adaptyApiKey: "your_adapty_api_key",
    paywallName: "your_paywall_name",
    sdkKey: "your_sdk_key"
)

// With custom entitlement ID (optional, default: "premium")
IAPKit.store.activate(
    adaptyApiKey: "your_adapty_api_key",
    paywallName: "your_paywall_name",
    entitlementId: "pro",
    sdkKey: "your_sdk_key"
)

// Set timeout for primary fetcher (optional, default: 5 seconds)
IAPKit.store.primaryTimeoutDuration = 3
```

#### Option B: Using RevenueCat

```swift
import IAPKit

// Configure IAPKit with RevenueCat
IAPKit.store.activate(
    revenueCatApiKey: "your_revenuecat_api_key",
    offeringId: "your_offering_id",
    entitlementId: "premium",
    sdkKey: "your_sdk_key"
)

// Set timeout for primary fetcher (optional, default: 5 seconds)
IAPKit.store.primaryTimeoutDuration = 3
```

> **Note:** Both providers use StoreKit as a fallback when the primary provider times out.

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

IAPKit provides a flexible logging system through the `IAPKitLoggable` protocol. You can integrate it with any logging framework.

### IAPKitLoggable Protocol

```swift
public protocol IAPKitLoggable: AnyObject {
    func logError(_ error: Error, context: String?)
}
```

### Integration with Firebase Crashlytics

```swift
import FirebaseCrashlytics

class CrashlyticsLogger: IAPKitLoggable {
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

class OSLogger: IAPKitLoggable {
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
class AnalyticsLogger: IAPKitLoggable {
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
class CompositeLogger: IAPKitLoggable {
    private let loggers: [IAPKitLoggable]
    
    init(loggers: [IAPKitLoggable]) {
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

### Live Paywall (RevenueCat Only)

RevenueCat's remote paywall feature allows you to design and update your paywall UI from the RevenueCat dashboard without app updates. This feature requires iOS 15.0+.

#### SwiftUI

```swift
import SwiftUI

struct ContentView: View {
    @State private var paywallView: AnyView?
    @State private var showPaywall = false

    var body: some View {
        Button("Show Paywall") {
            IAPKit.store.getPaywallView { view in
                if let view = view {
                    self.paywallView = view
                    self.showPaywall = true
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            paywallView
        }
    }
}
```

#### UIKit

```swift
import UIKit

class ViewController: UIViewController {

    @IBAction func showPaywallTapped(_ sender: Any) {
        IAPKit.store.getPaywallViewController { [weak self] viewController in
            if let vc = viewController {
                self?.present(vc, animated: true)
            }
        }
    }

    // With delegate for purchase events
    @IBAction func showPaywallWithDelegateTapped(_ sender: Any) {
        IAPKit.store.getPaywallViewController(delegate: self) { [weak self] viewController in
            if let vc = viewController {
                self?.present(vc, animated: true)
            }
        }
    }
}

// Implement PaywallViewControllerDelegate from RevenueCatUI
extension ViewController: PaywallViewControllerDelegate {
    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasingWith customerInfo: CustomerInfo) {
        // Handle successful purchase
    }
}
```

#### Changing Placement

```swift
// Change placement/offering and show new paywall
IAPKit.store.setPlacement("settings_paywall")

IAPKit.store.getPaywallView { view in
    // Shows paywall for "settings_paywall" placement
}
```

> **Note:** `getPaywallView` and `getPaywallViewController` automatically fetch offerings if not already loaded. No need to call `requestProducts()` first.

## Credits System

IAPKit v2 introduces a built-in credits management system for apps that use coin/credit-based monetization.

### Initialize Credits Manager

```swift
let creditsManager = CreditsManager()
```

### Basic Usage

```swift
// Refresh user credits from server
try await creditsManager.refresh()

// Access current credits
if let credits = creditsManager.credits {
    print("Total coins: \(credits.totalCoins)")
    print("Gift coins: \(credits.giftCoins)")
    print("Subscription coins: \(credits.subscriptionCoins)")
    print("Is subscription active: \(credits.isSubscriptionActive)")
}

// Claim gift coins (one-time)
let claimed = await creditsManager.claimGiftCoins()

// Spend credits
let remainingCoins = try await creditsManager.spendCredit(amount: 1)

// Get available credit products for purchase
let products = try await creditsManager.getCreditProducts()

// Check if user should see paywall
let shouldShowPaywall = creditsManager.checkCreditAndSubsStatus()
```

## Error Handling

IAPKit provides comprehensive error handling through the logging system. Common error contexts include:

### Adapty Contexts
- **"Adapty Activate"**: Issues during Adapty SDK initialization
- **Paywall Names**: Errors related to specific paywalls
- **"Cancelled payment by closing it"**: User cancelled the payment flow

### RevenueCat Contexts
- **"RevenueCat identify"**: Issues during user identification
- **"RevenueCat getOfferings"**: Errors fetching offerings
- **"RevenueCat fetchPaywall"**: Errors fetching paywall configuration
- **"RevenueCat fetchProfile"**: Errors fetching customer info
- **"RevenueCat purchase"**: Purchase transaction errors
- **"RevenueCat purchase cancelled"**: User cancelled the purchase
- **"RevenueCat restorePurchases"**: Restore purchases errors
- **"RevenueCat buy - product not found"**: Product not found in current offering

## Migration from v1 to v2

### Breaking Changes

1. **`activate()` now requires `sdkKey` parameter:**

   The `sdkKey` is a required, app-specific key that you need to obtain from us.

```swift
// v1 (deprecated)
IAPKit.store.activate(adaptyApiKey: "key", paywallName: "paywall")

// v2
IAPKit.store.activate(adaptyApiKey: "key", paywallName: "paywall", sdkKey: "your_sdk_key")
```

2. **`adaptyTimeoutDuration` renamed to `primaryTimeoutDuration`:**

```swift
// v1 (deprecated)
IAPKit.store.adaptyTimeoutDuration = 3

// v2
IAPKit.store.primaryTimeoutDuration = 3
```

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 14.0+

## Dependencies

- [Adapty SDK](https://github.com/adaptyteam/AdaptySDK-iOS) (3.11.0) - *Required for Adapty integration*
- [RevenueCat SDK](https://github.com/RevenueCat/purchases-ios) (5.50.0+) - *Required for RevenueCat integration*
- [RevenueCatUI](https://github.com/RevenueCat/purchases-ios) - *Required for Live Paywall feature*
- [RxSwift](https://github.com/ReactiveX/RxSwift) (6.6.0+)
- [MobKitCore](https://github.com/mobven/MobKitCore) (1.0.1+) - *Required for networking*

## License

[Add your license information here]

## Contributing

[Add contribution guidelines here]

## Support

[Add support contact information here] 



