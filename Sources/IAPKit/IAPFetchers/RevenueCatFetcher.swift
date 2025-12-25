//
//  RevenueCatFetcher.swift
//  IAPKit
//
//  Created by IAPKit on 22.12.2024.
//

import Foundation
import RevenueCat
import StoreKit

/// RevenueCat implementation of IAPFetcherProtocol
final class RevenueCatFetcher: NSObject, IAPFetcherProtocol {
    
    // MARK: - Properties
    
    var fetcherType: IAPFetcherType { .revenueCat }
    weak var logger: IAPKitLoggable?
    
    private var offerings: Offerings?
    private var currentOffering: Offering?
    private var placementId: String = ""
    private var entitlementId: String = "premium"
    
    private var isRevenueCatFetchingProducts: Bool = false
    private var pendingPurchase: (product: IAPProduct, completion: (Result<IAPSubscription, Error>) -> Void)?
    private var purchaseRetryCount: Int = 0
    private let maxPurchaseRetries: Int = 1
    
    // MARK: - Lifecycle
    
    func activate(apiKey: String, placementName: String, entitlementId: String) {
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
    
    func identify(_ userID: String) {
        Purchases.shared.logIn(userID) { [weak self] _, _, error in
            if let error = error {
                self?.logger?.logError(error, context: "RevenueCat identify")
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
