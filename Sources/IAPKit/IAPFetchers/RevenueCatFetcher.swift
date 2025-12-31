//
//  RevenueCatFetcher.swift
//  IAPKit
//
//  Created by IAPKit on 22.12.2024.
//

import Foundation
import RevenueCat
import RevenueCatUI
import StoreKit
import SwiftUI

import UIKit

/// Callback type for live paywall purchase events
typealias LivePaywallPurchaseHandler = (IAPProduct, String?) -> Void
typealias LivePaywallFailureHandler = (IAPProduct?, Error) -> Void

/// RevenueCat implementation of ManagedIAPProvider
final class RevenueCatFetcher: NSObject, ManagedIAPProvider {

    // MARK: - Properties

    var fetcherType: IAPFetcherType { .revenueCat }
    weak var logger: IAPKitLoggable?

    /// Called when a purchase is completed through the live paywall
    var onLivePaywallPurchase: LivePaywallPurchaseHandler?
    /// Called when a purchase fails through the live paywall
    var onLivePaywallFailure: LivePaywallFailureHandler?

    private var offerings: Offerings?
    private var currentOffering: Offering?
    private var placementId: String = ""
    private var entitlementId: String = "premium"
    
    private var isRevenueCatFetchingProducts: Bool = false
    private var pendingPurchase: (product: IAPProduct, completion: (Result<IAPSubscription, Error>) -> Void)?
    private var purchaseRetryCount: Int = 0
    private let maxPurchaseRetries: Int = 1
    
    // MARK: - Lifecycle
    
    func activate(apiKey: String, placementName: String, entitlementId: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.placementId = placementName
        self.entitlementId = entitlementId

        // Map IAPKit log level to RevenueCat log level
        switch IAPKitLogLevel.logLevel {
        case .debug:
            Purchases.logLevel = .debug
        case .prod:
            Purchases.logLevel = .error
        }
        Purchases.configure(withAPIKey: apiKey)

        logger?.log("RevenueCat activated with placement: \(placementName), entitlement: \(entitlementId)")

        // RevenueCat configure is synchronous, so we can immediately return success
        completion?(.success(()))
    }
    
    func setPlacement(_ placementName: String) {
        let wasLoaded = self.currentOffering != nil
        self.placementId = placementName
        self.currentOffering = nil

        // Re-fetch if offerings were previously loaded
        if wasLoaded {
            fetch { _ in }
        }
    }
    
    func logout() {
        Purchases.shared.logOut { _, _ in }
    }
    
    func identify(_ userID: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        Purchases.shared.logIn(userID) { [weak self] _, _, error in
            if let error = error {
                self?.logger?.logError(error, context: "RevenueCat identify")
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }
        }
    }
    
    // MARK: - Products
    
    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void)) {
        isRevenueCatFetchingProducts = true
        
        Purchases.shared.getOfferings { [weak self] offerings, error in
            guard let self = self else { return }
            self.isRevenueCatFetchingProducts = false
            
            if let error = error {
                self.logger?.logError(error, context: "RevenueCat getOfferings")
                completion(.failure(error))
                return
            }
            
            guard let offerings = offerings else {
                completion(.success(IAPProducts(products: [])))
                return
            }
            
            self.offerings = offerings

            // Get offering for placement or fall back to current
            let offering: Offering?
            if !self.placementId.isEmpty {
                offering = offerings.currentOffering(forPlacement: self.placementId)
            } else {
                offering = offerings.current
            }

            guard let currentOffering = offering else {
                self.logger?.log("RevenueCat: No offering found for placement: \(self.placementId)")
                completion(.success(IAPProducts(products: [])))
                return
            }
            
            self.currentOffering = currentOffering
            
            // Convert RevenueCat packages to IAPProducts
            let products = currentOffering.availablePackages.compactMap { package -> IAPProduct? in
                self.createIAPProduct(from: package.storeProduct)
            }
            
            let iapProducts = IAPProducts(
                products: products,
                config: currentOffering.metadata as? [String: Any],
                paywallId: currentOffering.identifier
            )
            
            completion(.success(iapProducts))
            
            // Handle pending purchase if any
            if let pending = self.pendingPurchase {
                self.buy(product: pending.product, completion: pending.completion)
                self.pendingPurchase = nil
            }
        }
    }
    
    func fetchPaywall(completion: @escaping ((Result<String, Error>) -> Void)) {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error = error {
                self?.logger?.logError(error, context: "RevenueCat fetchPaywall")
                completion(.failure(error))
                return
            }

            let offering: Offering?
            if let placementId = self?.placementId, !placementId.isEmpty {
                offering = offerings?.currentOffering(forPlacement: placementId)
            } else {
                offering = offerings?.current
            }

            completion(.success(offering?.identifier ?? ""))
        }
    }
    
    // MARK: - Profile
    
    func fetchProfile(completion: @escaping (Result<IAPProfile, Error>) -> Void) {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger?.logError(error, context: "RevenueCat fetchProfile")
                completion(.failure(error))
                return
            }
            
            let isSubscribed = customerInfo?.entitlements[self.entitlementId]?.isActive ?? false
            let expireDate = customerInfo?.entitlements[self.entitlementId]?.expirationDate
            
            completion(.success(IAPProfile(
                isSubscribed: isSubscribed,
                expireDate: expireDate
            )))
        }
    }
    
    // MARK: - Purchases
    
    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        // Find the package matching the product
        guard let package = currentOffering?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == product.identifier
        }) else {
            // If products aren't loaded yet, queue the purchase
            if isRevenueCatFetchingProducts {
                pendingPurchase = (product: product, completion: completion)
                return
            }

            // Prevent infinite retry loop - only retry once
            guard purchaseRetryCount < maxPurchaseRetries else {
                purchaseRetryCount = 0
                let error = NSError(
                    domain: SKErrorDomain,
                    code: SKError.unknown.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Product not found in current offering after retry. Product ID: \(product.identifier)"]
                )
                logger?.logError(error, context: "RevenueCat buy - product not found")
                completion(.failure(error))
                return
            }

            // Try fetching products first
            purchaseRetryCount += 1
            fetch { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.buy(product: product, completion: completion)
                case .failure(let error):
                    self.purchaseRetryCount = 0
                    self.logger?.logError(error, context: "RevenueCat buy - fetch failed")
                    completion(.failure(error))
                }
            }
            return
        }

        // Reset retry count on successful package find
        purchaseRetryCount = 0
        
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            guard let self = self else { return }
            
            if userCancelled {
                let cancelError = NSError(
                    domain: SKErrorDomain,
                    code: SKError.paymentCancelled.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled by user"]
                )
                self.logger?.logError(cancelError, context: "RevenueCat purchase cancelled")
                completion(.failure(cancelError))
                return
            }
            
            if let error = error {
                self.logger?.logError(error, context: "RevenueCat purchase")
                completion(.failure(error))
                return
            }
            
            // Log transaction if available
            if let transaction = transaction {
                self.logger?.log("RevenueCat purchase successful: \(transaction.transactionIdentifier)")
            }

            // Check if the entitlement is now active
            let isActive = customerInfo?.entitlements[self.entitlementId]?.isActive ?? false

            let subscription = IAPSubscription(
                vendorTransactionId: transaction?.transactionIdentifier ?? "",
                activatedAt: transaction?.purchaseDate ?? Date(),
                isInGracePeriod: false,
                activeIntroductoryOfferType: nil,
                vendorProductId: product.identifier,
                vendorOriginalTransactionId: transaction?.transactionIdentifier ?? ""
            )
            
            if isActive {
                completion(.success(subscription))
            } else {
                // Purchase went through but entitlement not active - unusual but handle it
                self.logger?.log("RevenueCat: Purchase completed but entitlement not active")
                completion(.success(subscription))
            }
        }
    }
    
    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger?.logError(error, context: "RevenueCat restorePurchases")
                completion(.failure(error))
                return
            }
            
            let isPremium = customerInfo?.entitlements[self.entitlementId]?.isActive ?? false
            completion(.success(isPremium))
        }
    }
    
    // MARK: - Attribution
    
    func setPlayerId(_ playerId: String?) {
        guard let playerId = playerId, !playerId.isEmpty else { return }
        Purchases.shared.attribution.setOnesignalUserID(playerId)
    }
    
    func setFirebaseId(_ id: String?) {
        guard let id = id, !id.isEmpty else { return }
        Purchases.shared.attribution.setFirebaseAppInstanceID(id)
    }
    
    func setAdjustDeviceId(_ adjustId: String?) {
        guard let adjustId = adjustId, !adjustId.isEmpty else { return }
        Purchases.shared.attribution.setAdjustID(adjustId)
    }
    
    // MARK: - Private Helpers
    
    private func createIAPProduct(from storeProduct: StoreProduct) -> IAPProduct? {
        if #available(iOS 15.0, *) {
            if let sk2Product = storeProduct.sk2Product {
                return IAPProduct(product: sk2Product)
            }
        }

        // Fallback to SK1
        if let sk1Product = storeProduct.sk1Product {
            return IAPProduct(product: sk1Product)
        }

        return nil
    }

}

// MARK: - PaywallProvidable

@available(iOS 15.0, *)
extension RevenueCatFetcher: PaywallProvidable {

    func getPaywallView(completion: @escaping (AnyView) -> Void) {
        ensureOfferingLoaded { [weak self] offering in
            guard let self = self else { return }
            completion(self.createPaywallView(offering: offering))
        }
    }

    func getPaywallViewController(delegate: Any?, completion: @escaping (UIViewController) -> Void) {
        ensureOfferingLoaded { [weak self] offering in
            guard let self = self else { return }
            completion(self.createPaywallViewController(offering: offering, delegate: delegate))
        }
    }

    // MARK: - Private Helpers

    private func ensureOfferingLoaded(completion: @escaping (Offering?) -> Void) {
        if let offering = currentOffering {
            completion(offering)
            return
        }

        fetch { [weak self] _ in
            DispatchQueue.main.async {
                completion(self?.currentOffering)
            }
        }
    }

    private func createPaywallView(offering: Offering?) -> AnyView {
        let paywallView: PaywallView
        if let offering = offering {
            paywallView = PaywallView(offering: offering)
        } else {
            paywallView = PaywallView()
        }

        // Wrap with purchase handler
        let wrappedView = paywallView
            .onPurchaseCompleted { [weak self] customerInfo in
                self?.handleLivePaywallPurchaseFromCustomerInfo(customerInfo: customerInfo)
            }
            .onPurchaseFailure { [weak self] error in
                self?.handleLivePaywallFailure(error: error)
            }

        return AnyView(wrappedView)
    }

    private func createPaywallViewController(offering: Offering?, delegate: Any?) -> PaywallViewController {
        let controller: PaywallViewController
        if let offering = offering {
            controller = PaywallViewController(offering: offering)
        } else {
            controller = PaywallViewController()
        }

        // Create internal delegate wrapper to intercept purchase events
        let delegateWrapper = PaywallDelegateWrapper(
            fetcher: self,
            userDelegate: delegate as? PaywallViewControllerDelegate
        )
        controller.delegate = delegateWrapper

        // Store wrapper to prevent deallocation
        objc_setAssociatedObject(
            controller,
            &AssociatedKeys.delegateWrapper,
            delegateWrapper,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        return controller
    }

    fileprivate func handleLivePaywallPurchaseFromCustomerInfo(customerInfo: CustomerInfo) {
        // Try to find the most recently purchased product from the entitlement
        let activeEntitlement = customerInfo.entitlements[entitlementId]
        guard let productId = activeEntitlement?.productIdentifier else {
            logger?.log("Live paywall purchase completed but no product identifier found in entitlement")
            // Still notify with nil product info - purchase happened
            notifyPurchaseSuccess(productId: nil)
            return
        }

        notifyPurchaseSuccess(productId: productId)
    }

    fileprivate func handleLivePaywallPurchase(customerInfo: CustomerInfo, productId: String?) {
        guard let productId = productId else {
            handleLivePaywallPurchaseFromCustomerInfo(customerInfo: customerInfo)
            return
        }
        notifyPurchaseSuccess(productId: productId)
    }

    private func notifyPurchaseSuccess(productId: String?) {
        let paywallId = currentOffering?.identifier

        guard let productId = productId else {
            // Create a placeholder product when we don't know the exact product
            let product = IAPProduct(identifier: "unknown")
            logger?.log("Live paywall purchase completed (unknown product)")
            onLivePaywallPurchase?(product, paywallId)
            return
        }

        // Find the IAPProduct from current offering
        if let package = currentOffering?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == productId
        }),
           let iapProduct = createIAPProduct(from: package.storeProduct) {
            logger?.log("Live paywall purchase completed: \(productId)")
            onLivePaywallPurchase?(iapProduct, paywallId)
        } else {
            // Create a minimal product with just the identifier
            let product = IAPProduct(identifier: productId)
            logger?.log("Live paywall purchase completed (minimal): \(productId)")
            onLivePaywallPurchase?(product, paywallId)
        }
    }

    fileprivate func handleLivePaywallFailure(error: Error) {
        logger?.logError(error, context: "Live paywall purchase")
        onLivePaywallFailure?(nil, error)
    }
}

// MARK: - Associated Keys

private struct AssociatedKeys {
    static var delegateWrapper = "delegateWrapper"
}

// MARK: - Paywall Delegate Wrapper

@available(iOS 15.0, *)
private class PaywallDelegateWrapper: NSObject, PaywallViewControllerDelegate {
    private weak var fetcher: RevenueCatFetcher?
    private var userDelegate: PaywallViewControllerDelegate?

    init(fetcher: RevenueCatFetcher, userDelegate: PaywallViewControllerDelegate?) {
        self.fetcher = fetcher
        self.userDelegate = userDelegate
        super.init()
    }

    func paywallViewController(
        _ controller: PaywallViewController,
        didFinishPurchasingWith customerInfo: CustomerInfo
    ) {
        // Notify IAPKit delegate
        fetcher?.handleLivePaywallPurchaseFromCustomerInfo(customerInfo: customerInfo)
        // Forward to user delegate if provided
        userDelegate?.paywallViewController?(controller, didFinishPurchasingWith: customerInfo)
    }
}

