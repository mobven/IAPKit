//
//  AdaptyFetcher.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Adapty
import Foundation

protocol SDKLogger: AnyObject {
    func logError(_ error: Error, context: String?)
}

final class AdaptyFetcher: NSObject, IAPProductFetchable {
    var products: [AdaptyPaywallProduct] = []
    
    weak var delegate: SDKLogger?

    var placementName = ""

    private var isAdaptyFetchingProducts: Bool = false
    private var pendingPurchase: (product: IAPProduct, completion: (Result<IAPSubscription, Error>) -> Void)?

    func activate(adaptyApiKey apiKey: String, paywallName: String) {
        placementName = paywallName
        Adapty.activate(apiKey) { [weak self] result in
            if let error = result {
                self?.delegate?.logError(error, context: "Adapty Activate")
            }
        }
    }

    func fetchPaywall(completion: @escaping (Result<String, Error>) -> Void) {
        let locale = Locale.current.identifier
        Adapty.getPaywall(placementId: placementName, locale: locale) { result in
            switch result {
            case let .success(paywall):
                completion(.success(paywall.name))
            case let .failure(error):
                completion(.failure(error))
            }
        }
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
                        let iapProducts: [IAPProduct] = products.compactMap { product in
                            if #available(iOS 15.0, *) {
                                // StoreKit 2
                                if let sk2 = product.sk2Product {
                                    return IAPProduct(product: sk2)
                                } // if SK2 is missing (rare), fall back to StoreKit 1
                                else if let sk1 = product.sk1Product {
                                    return IAPProduct(product: sk1)
                                }
                            } else {
                                // iOS 13–14: StoreKit 1 only
                                if let sk1 = product.sk1Product {
                                    return IAPProduct(product: sk1)
                                }
                            }
                            return nil
                        }
                        completion(.success(IAPProducts(
                            products: iapProducts,
                            config: paywall.remoteConfig?.dictionary,
                            paywallId: paywall.instanceIdentity
                        )))
                        if let pendingPurchase {
                            buy(product: pendingPurchase.product, completion: pendingPurchase.completion)
                        }
                    case let .failure(error):
                        self.delegate?.logError(error, context: paywall.name)
                        completion(.failure(error))
                        if let pendingPurchase {
                            pendingPurchase.completion(.failure(NSError(domain: "IAPAdaptyFetcherError", code: 33001)))
                        }
                    }
                }
            case let .failure(error):
                self.delegate?.logError(error, context: self.placementName)
                completion(.failure(error))
            }
        }
    }

    func fetchProfile(completion: @escaping ((Result<IAPProfile, Error>) -> Void)) {
        Adapty.getProfile { [weak self] result in
            switch result {
            case let .success(profile):
                let isSubscribed = profile.isPremium
                let expireDate = profile.subscriptions.first(where: { $0.value.isActive })?.value.expiresAt
                completion(.success(IAPProfile(isSubscribed: isSubscribed, expireDate: expireDate)))
            case let .failure(error):
                self?.delegate?.logError(error, context: self?.placementName)
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
                            self.delegate?.logError(error, context: self.placementName)
                            completion(.failure(error))
                        }
                    }
                }
            case let .failure(error):
                self.delegate?.logError(error, context: placementName)
                completion(.failure(error))
            }
        }
    }

    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        guard let adaptyProduct = products
            .first(where: { product.identifier == $0.vendorProductId })
        else {
            waitForProductsThenBuy(product: product, completion: completion)
            return
        }
        Adapty.makePurchase(product: adaptyProduct) { [weak self] result in
            switch result {
            case let .success(info):
                guard !info.isPurchaseCancelled else {
                    let error = NSError(domain: "Cancelled payment by closing it", code: 404)
                    self?.delegate?.logError(error, context: self?.placementName)
                    completion(.failure(error))
                    return
                }
                let subscription = info.profile?.subscriptions[adaptyProduct.vendorProductId]
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
                self?.delegate?.logError(error, context: self?.placementName)
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
        Task {
            try? await Adapty.setIntegrationIdentifier(
                key: "one_signal_player_id",
                value: playerId ?? ""
            )
        }
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
