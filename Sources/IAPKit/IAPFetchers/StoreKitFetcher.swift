//
//  StoreKitFetcher.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Foundation
import StoreKit

enum StoreError: Error {
    case failedVerification
}

final class StoreKitFetcher: NSObject, IAPProductFetchable {
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

    @available(
        *, unavailable, message: "Not implemented or used currently! Would be alternative to Adapty to give timeout"
    ) func fetchProfile(completion: @escaping ((Result<IAPProfile, Error>) -> Void)) {
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
            // TODO: fallback?
        }
    }

    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        if #available(iOS 15, *) {
            Task {
                do {
                    
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
                } catch {
                    completion(.failure(error))
                }
            }
        } else {
            // For iOS 14 and earlier, StoreKit 1 doesn't provide a reliable way to check
            // subscription status without server-side receipt validation.
            // We trigger restore but return false to let Adapty handle the actual verification
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

extension StoreKitFetcher: SKProductsRequestDelegate {
    func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products.compactMap { IAPProduct(product: $0) }
        completion?(.success(IAPProducts(products: getSortedProducts(products))))
    }
}

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

/*
 extension StoreKitFetcher: SKRequestDelegate {
     func requestDidFinish(_ request: SKRequest) {
         // TODO: restore purchases?
     }
     func request(_ request: SKRequest, didFailWithError error: Error) {
         // TODO: fail to restore purchases
     }
 }
 */
