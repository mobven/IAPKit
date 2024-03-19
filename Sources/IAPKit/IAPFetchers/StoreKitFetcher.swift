//
//  StoreKitFetcher.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Foundation
import StoreKit

final class StoreKitFetcher: NSObject, IAPProductFetchable {
    // swiftlint:disable implicitly_unwrapped_optional
    var request: SKProductsRequest!
    // swiftlint:enable implicitly_unwrapped_optional

    var completion: ((Result<[IAPProduct], Error>) -> Void)?

    let productIdentifiers = Set(
        [
            WeeklyProduct.productIdentifier,
            MonthlyProduct.productIdentifier
        ]
    )

    func fetch(completion: @escaping ((Result<[IAPProduct], Error>) -> Void)) {
        if #available(iOS 15, *) {
            Task {
                let products = try await Product.products(for: productIdentifiers)
                completion(.success(getSortedProducts(products.compactMap { IAPProduct(product: $0) })))
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

    @available(
        *, unavailable, message: "Not implemented or used currently! Would be alternative to Adapty to give timeout"
    ) func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        let refresh = SKReceiptRefreshRequest()
        refresh.delegate = self
        refresh.start()
    }
}

extension StoreKitFetcher: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products.compactMap { IAPProduct(product: $0) }
        completion?(.success(getSortedProducts(products)))
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
