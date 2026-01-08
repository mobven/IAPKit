//
//  IAPProductFetcher.swift
//  IAPKit
//
//  Created by Rashid Ramazanov on 23.01.2024.
//  Refactored as Coordinator on 22.12.2024.
//

import Foundation
import StoreKit
import SwiftUI
import UIKit

/// Coordinator that manages primary (Adapty/RevenueCat) and fallback (StoreKit) fetchers
final class IAPProductFetcher {
    // MARK: - Properties

    /// Primary fetcher - managed providers like Adapty or RevenueCat
    private var primaryFetcher: ManagedIAPProvider?

    /// Fallback fetcher - native StoreKit (only conforms to ProductFetchable)
    private let fallbackFetcher: StoreKitFetcher

    /// Called when a purchase is completed through the live paywall
    var onLivePaywallPurchase: LivePaywallPurchaseHandler? {
        didSet {
            (primaryFetcher as? RevenueCatFetcher)?.onLivePaywallPurchase = onLivePaywallPurchase
        }
    }

    /// Called when a purchase fails through the live paywall
    var onLivePaywallFailure: LivePaywallFailureHandler? {
        didSet {
            (primaryFetcher as? RevenueCatFetcher)?.onLivePaywallFailure = onLivePaywallFailure
        }
    }

    /// Timeout for primary fetcher before falling back to StoreKit
    var timeout: TimeInterval = 5

    /// Backward compatibility alias
    var adaptyTimeout: TimeInterval {
        get { timeout }
        set { timeout = newValue }
    }

    var defaultProducts: IAPProducts = .init(products: [])

    var logger: IAPKitLoggable? {
        didSet {
            primaryFetcher?.logger = logger
            fallbackFetcher.logger = logger
        }
    }

    // MARK: - Initialization

    init() {
        fallbackFetcher = StoreKitFetcher()
    }

    // MARK: - Activation

    /// Activate with Adapty as primary fetcher
    func activate(adaptyApiKey apiKey: String, paywallName: String, entitlementId: String = "premium") {
        let adaptyFetcher = AdaptyFetcher()
        adaptyFetcher.logger = logger
        adaptyFetcher.activate(
            apiKey: apiKey,
            placementName: paywallName,
            entitlementId: entitlementId,
            customerUserId: IAPUser.current.deviceId
        )
        primaryFetcher = adaptyFetcher
    }

    /// Activate with RevenueCat as primary fetcher
    func activate(revenueCatApiKey apiKey: String, offeringId: String, entitlementId: String = "premium") {
        let revenueCatFetcher = RevenueCatFetcher()
        revenueCatFetcher.logger = logger
        revenueCatFetcher.onLivePaywallPurchase = onLivePaywallPurchase
        revenueCatFetcher.onLivePaywallFailure = onLivePaywallFailure
        revenueCatFetcher.activate(
            apiKey: apiKey,
            placementName: offeringId,
            entitlementId: entitlementId,
            customerUserId: IAPUser.current.deviceId
        )
        primaryFetcher = revenueCatFetcher
    }

    /// Set placement/offering name
    func setPlacement(_ placementName: String) {
        primaryFetcher?.setPlacement(placementName)
    }

    // MARK: - Products

    /// Fetch products with timeout fallback to StoreKit
    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void)) {
        guard let primaryFetcher else {
            // No primary fetcher configured, use StoreKit directly
            fallbackFetcher.fetch(completion: completion)
            return
        }

        // If timeout is zero, fetch from both but return StoreKit results for display
        if timeout == .zero {
            // Call primary to prepare products for purchase
            primaryFetcher.fetch { _ in }
            // Return StoreKit results for display (faster)
            fallbackFetcher.fetch(completion: completion)
            return
        }

        // Thread-safe state management
        let stateQueue = DispatchQueue(label: "com.iapkit.fetchstate")
        var hasCompleted = false

        // Use DispatchWorkItem for cancellable timeout
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }

            var shouldFallback = false
            stateQueue.sync {
                guard !hasCompleted else { return }
                hasCompleted = true
                shouldFallback = true
            }

            if shouldFallback {
                logger?.log("Primary fetcher timed out, falling back to StoreKit")
                fallbackFetcher.fetch(completion: completion)
            }
        }

        // Schedule timeout on main queue
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        // Fetch from primary
        primaryFetcher.fetch { result in
            var shouldComplete = false
            stateQueue.sync {
                guard !hasCompleted else { return }
                hasCompleted = true
                shouldComplete = true
            }

            if shouldComplete {
                // Cancel timeout work item
                timeoutWorkItem.cancel()
                completion(result)
            }
        }
    }

    /// Fetch paywall/offering name
    func fetchPaywallName(completion: @escaping ((String?) -> Void)) {
        guard let primaryFetcher else {
            completion(nil)
            return
        }
        primaryFetcher.fetchPaywall { result in
            switch result {
            case let .success(name):
                completion(name)
            case let .failure(error):
                completion(error.localizedDescription)
                // TODO: IAPKit hatalarını özel bir Error tipinde döndürebiliriz.
            }
        }
    }

    // MARK: - Profile

    /// Fetch profile from primary fetcher only
    func fetchProfile(completion: @escaping ((Result<IAPProfile, Error>) -> Void)) {
        guard let primaryFetcher else {
            let error = NSError(
                domain: "IAPProductFetcher",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No primary fetcher configured"]
            )
            completion(.failure(error))
            return
        }
        primaryFetcher.fetchProfile(completion: completion)
    }

    // MARK: - Purchases

    /// Buy product using primary fetcher
    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        guard let primaryFetcher else {
            let error = NSError(
                domain: "IAPProductFetcher",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No primary fetcher configured"]
            )
            completion(.failure(error))
            return
        }
        primaryFetcher.buy(product: product, completion: completion)
    }

    /// Restore purchases from both primary and StoreKit in parallel
    /// Returns success if either returns true
    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        guard let primaryFetcher else {
            // No primary, just use StoreKit
            fallbackFetcher.restorePurchases(completion: completion)
            return
        }

        let group = DispatchGroup()
        var primaryResult: Result<Bool, Error>?
        var storeKitResult: Result<Bool, Error>?

        // Call primary restore
        group.enter()
        primaryFetcher.restorePurchases { result in
            primaryResult = result
            group.leave()
        }

        // Call StoreKit restore
        group.enter()
        fallbackFetcher.restorePurchases { result in
            storeKitResult = result
            group.leave()
        }

        // Wait for both to complete
        group.notify(queue: .main) {
            let primarySuccess = (try? primaryResult?.get()) ?? false
            let storeKitSuccess = (try? storeKitResult?.get()) ?? false

            // If either returns true, return success
            if primarySuccess || storeKitSuccess {
                completion(.success(true))
                return
            }

            // Both returned false or error - return primary's result
            if let primaryResult {
                completion(primaryResult)
            } else {
                completion(.success(false))
            }
        }
    }

    // MARK: - User Management

    func logout() {
        primaryFetcher?.logout()
    }

    func identify(_ userID: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        primaryFetcher?.identify(userID, completion: completion)
    }

    // MARK: - Attribution

    func setPlayerId(_ playerId: String?) {
        primaryFetcher?.setPlayerId(playerId)
    }

    func setFirebaseId(_ id: String?) {
        primaryFetcher?.setFirebaseId(id)
    }

    func setAdjustDeviceId(_ adjustId: String?) {
        primaryFetcher?.setAdjustDeviceId(adjustId)
    }

    // MARK: - Paywall UI

    @available(iOS 15.0, *) func getPaywallView(completion: @escaping (AnyView?) -> Void) {
        guard let paywallProvider = primaryFetcher as? PaywallProvidable else {
            // TODO: sadece revenuecat ile çalışıyor hatası verilebilir. aşağıda da aynı şekilde.
            completion(nil)
            return
        }
        paywallProvider.getPaywallView { view in
            completion(view)
        }
    }

    @available(iOS 15.0, *)
    func getPaywallViewController(delegate: Any?, completion: @escaping (UIViewController?) -> Void) {
        guard let paywallProvider = primaryFetcher as? PaywallProvidable else {
            completion(nil)
            return
        }
        paywallProvider.getPaywallViewController(delegate: delegate) { viewController in
            completion(viewController)
        }
    }
}
