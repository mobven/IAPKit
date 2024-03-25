//
//  AdaptyFetcher.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Adapty
import Foundation

final class AdaptyFetcher: NSObject, IAPProductFetchable {
    var products: [AdaptyPaywallProduct] = []

    var placementName = ""

    private var isAdaptyFetchingProducts: Bool = false
    private var pendingPurchase: (product: IAPProduct, completion: (Result<IAPSubscription, Error>) -> Void)?

    func activate(adaptyApiKey apiKey: String, paywallName: String) {
        placementName = paywallName
        Adapty.activate(apiKey)
    }

    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void)) {
        isAdaptyFetchingProducts = true
        let locale = Locale.current.identifier
        Adapty.getPaywall(placementId: placementName, locale: locale) { result in
            switch result {
            case let .success(paywall):
                Adapty.getPaywallProducts(paywall: paywall) { [weak self] result in
                    guard let self else { return }
                    isAdaptyFetchingProducts = false
                    // TODO: @Alexey from Adapty suggested to move it to the view controller lifecycle.
                    Adapty.logShowPaywall(paywall)
                    switch result {
                    case let .success(products):
                        self.products = products
                        let iapProducts = products.compactMap { IAPProduct(product: $0.skProduct) }
                        completion(.success(IAPProducts(products: iapProducts, config: paywall.remoteConfig)))
                        if let pendingPurchase {
                            buy(product: pendingPurchase.product, completion: pendingPurchase.completion)
                        }
                    case let .failure(error):
                        completion(.failure(error))
                        if let pendingPurchase {
                            pendingPurchase.completion(.failure(NSError(domain: "IAPAdaptyFetcherError", code: 33001)))
                        }
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func fetchProfile(completion: @escaping ((Result<IAPProfile, Error>) -> Void)) {
        Adapty.getProfile { result in
            switch result {
            case let .success(profile):
                let isSubscribed = profile.isPremium
                let expireDate = profile.subscriptions.first(where: { $0.value.isActive })?.value.expiresAt
                completion(.success(IAPProfile(isSubscribed: isSubscribed, expireDate: expireDate)))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Adapty.restorePurchases { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(profile):
                if profile.isPremium {
                    completion(.success(true))
                } else {
                    fetchProfile { result in
                        switch result {
                        case let .success(profile):
                            completion(.success(profile.isSubscribed))
                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        guard let adaptyProduct = products
            .first(where: { product.identifier.hasPrefix($0.skProduct.productIdentifier) })
        else {
            waitForProductsThenBuy(product: product, completion: completion)
            return
        }
        Adapty.makePurchase(product: adaptyProduct) { result in
            switch result {
            case let .success(info):
                let subscription = info.profile.subscriptions[adaptyProduct.vendorProductId]
                completion(
                    .success(
                        IAPSubscription(
                            vendorTransactionId: subscription?.vendorTransactionId ?? "",
                            activatedAt: subscription?.activatedAt ?? Date(),
                            isInGracePeriod: subscription?.isInGracePeriod ?? false,
                            activeIntroductoryOfferType: subscription?.activeIntroductoryOfferType,
                            vendorProductId: subscription?.vendorProductId ?? "",
                            vendorOriginalTransactionId: subscription?.vendorOriginalTransactionId ?? ""
                        )
                    )
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func waitForProductsThenBuy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        if isAdaptyFetchingProducts {
            pendingPurchase = (product: product, completion: completion)
        } else {
            fetch { [weak self] _ in
                self?.buy(product: product, completion: completion)
            }
        }
    }

    func logout() {
        Adapty.logout()
    }

    func identify(_ userID: String) {
        Adapty.identify(userID)
    }

    func setPlayerId(_ playerId: String?) {
        let builder = AdaptyProfileParameters.Builder().with(oneSignalPlayerId: playerId)
        Adapty.updateProfile(params: builder.build())
    }
}

public struct IAPProfile {
    public let isSubscribed: Bool
    public let expireDate: Date?
}

extension AdaptyProfile {
    var isPremium: Bool {
        accessLevels["premium"]?.isActive ?? false
    }
}
