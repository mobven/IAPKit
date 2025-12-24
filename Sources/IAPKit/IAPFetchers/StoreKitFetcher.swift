//
//  StoreKitFetcher.swift
//  IAPKit
//
//  Created by Rashid Ramazanov on 23.01.2024.
//  Refactored to IAPFetcherProtocol on 22.12.2024.
//

import Foundation
import StoreKit

enum StoreError: Error {
    case failedVerification
}

/// StoreKit implementation of IAPFetcherProtocol (used as fallback)
final class StoreKitFetcher: NSObject, IAPFetcherProtocol {
    
    // MARK: - Properties
    
    var fetcherType: IAPFetcherType { .storeKit }
    weak var logger: IAPKitLoggable?
    
    // swiftlint:disable implicitly_unwrapped_optional
    var request: SKProductsRequest!
    // swiftlint:enable implicitly_unwrapped_optional

    var completion: ((Result<IAPProducts, Error>) -> Void)?

    let productIdentifiers = Set(
        [
            WeeklyProduct.productIdentifier,
            MonthlyProduct.productIdentifier,
        ]
    )
    
    // MARK: - Lifecycle

    func activate(apiKey: String, placementName: String, entitlementId: String) {
        // StoreKit doesn't need activation
    }
    
    func setPlacement(_ placementName: String) {
        // StoreKit doesn't use placements
    }
    
    func logout() {
        // StoreKit doesn't have logout
    }
    
    func identify(_ userID: String) {
        // StoreKit doesn't have identify
    }

    // MARK: - Products

    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void)) {
        if #available(iOS 15, *) {
            Task {
                let products = try await Product.products(for: productIdentifiers)
                let iapProducts = getSortedProducts(products.compactMap { IAPProduct(product: $0) })
                completion(.success(IAPProducts(products: iapProducts)))
            }
        } else {
            self.completion = completion
            request = SKProductsRequest(productIdentifiers: productIdentifiers)
            request.delegate = self
            request.start()
        }
    }
    
    // MARK: - Profile

    func fetchProfile(completion: @escaping (Result<IAPProfile, Error>) -> Void) {
        if #available(iOS 15, *) {
            Task {
                let products = try await Product.products(for: productIdentifiers)

                var isSubscribed: Bool = false
                var expireDate: Date?
                for product in products {
                    let subscription = product.subscription
                    do {
                        let status = try await subscription?.status
                        if status?.contains(where: { $0.state == .subscribed || $0.state == .inGracePeriod }) == true {
                            isSubscribed = true
                            expireDate = subscription?.subscriptionPeriod.dateRange().upperBound
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(IAPProfile(isSubscribed: isSubscribed, expireDate: expireDate)))
            }
        } else {
            // StoreKit 1 doesn't provide reliable subscription status
            completion(.success(IAPProfile(isSubscribed: false, expireDate: nil)))
        }
    }
    
    // MARK: - Purchases

    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        if #available(iOS 15, *) {
            // Use StoreKit 2 for purchases on iOS 15+
            Task {
                await buyWithStoreKit2(product: product, completion: completion)
            }
        } else {
            // StoreKit 1 purchase requires more complex implementation with payment queue observer
            // This is a fallback-only fetcher, so we recommend using Adapty or RevenueCat for purchases
            let error = NSError(
                domain: SKErrorDomain,
                code: SKError.unknown.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "StoreKit 1 direct purchases are not supported. Please configure Adapty or RevenueCat as your primary fetcher for purchase functionality."]
            )
            completion(.failure(error))
        }
    }

    @available(iOS 15, *)
    private func buyWithStoreKit2(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) async {
        do {
            // Find the StoreKit 2 Product
            let products = try await Product.products(for: [product.identifier])
            guard let storeProduct = products.first else {
                let error = NSError(
                    domain: SKErrorDomain,
                    code: SKError.invalidOfferIdentifier.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Product not found: \(product.identifier)"]
                )
                completion(.failure(error))
                return
            }

            // Attempt purchase
            let result = try await storeProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Finish the transaction
                await transaction.finish()

                let subscription = IAPSubscription(
                    vendorTransactionId: String(transaction.id),
                    activatedAt: transaction.purchaseDate,
                    isInGracePeriod: false,
                    activeIntroductoryOfferType: nil,
                    vendorProductId: product.identifier,
                    vendorOriginalTransactionId: String(transaction.originalID)
                )

                logger?.log("StoreKit 2 purchase successful: \(transaction.id)")
                completion(.success(subscription))

            case .userCancelled:
                let error = NSError(
                    domain: SKErrorDomain,
                    code: SKError.paymentCancelled.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled by user"]
                )
                completion(.failure(error))

            case .pending:
                let error = NSError(
                    domain: SKErrorDomain,
                    code: SKError.unknown.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Purchase is pending approval (e.g., Ask to Buy)"]
                )
                completion(.failure(error))

            @unknown default:
                let error = NSError(
                    domain: SKErrorDomain,
                    code: SKError.unknown.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"]
                )
                completion(.failure(error))
            }
        } catch StoreError.failedVerification {
            let error = NSError(
                domain: SKErrorDomain,
                code: SKError.unknown.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Transaction verification failed"]
            )
            logger?.logError(error, context: "StoreKit 2 purchase verification")
            completion(.failure(error))
        } catch {
            logger?.logError(error, context: "StoreKit 2 purchase")
            completion(.failure(error))
        }
    }

    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        if #available(iOS 15, *) {
            Task {
                var hasActiveEntitlement = false
                for await result in Transaction.currentEntitlements {
                    do {
                        let transaction = try checkVerified(result)
                        // If we have any verified entitlement, user has an active purchase
                        hasActiveEntitlement = true
                        await transaction.finish()
                        break
                    } catch {
                        // Failed to verify this transaction, continue checking others
                        continue
                    }
                }
                completion(.success(hasActiveEntitlement))
            }
        } else {
            // For iOS 14 and earlier, StoreKit 1 doesn't provide a reliable way to check
            // subscription status without server-side receipt validation.
            // We trigger restore but return false to let the main provider handle the actual verification
            SKPaymentQueue.default().restoreCompletedTransactions()
            completion(.success(false))
        }
    }
    
    @available(iOS 15, *)
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - SKProductsRequestDelegate

extension StoreKitFetcher: SKProductsRequestDelegate {
    func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products.compactMap { IAPProduct(product: $0) }
        completion?(.success(IAPProducts(products: getSortedProducts(products))))
    }
}

// MARK: - Helpers

extension StoreKitFetcher {
    func getSortedProducts(_ products: [IAPProduct]) -> [IAPProduct] {
        products.sorted { first, second -> Bool in
            if first.identifier == WeeklyProduct.productIdentifier {
                return true
            } else if second.identifier == WeeklyProduct.productIdentifier {
                return false
            }
            return false
        }
    }
}
