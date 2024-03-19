//
//  IAPProductFetcher.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Foundation
import StoreKit

protocol IAPProductFetchable {
    func fetch(completion: @escaping ((Result<[IAPProduct], Error>) -> Void))
}

final class IAPProductFetcher {
    private let adaptyFetcher: AdaptyFetcher
    private var skFetcher: StoreKitFetcher

    var adaptyTimeout: TimeInterval = 5

    init() {
        adaptyFetcher = AdaptyFetcher()
        skFetcher = StoreKitFetcher()
    }

    var completion: (([IAPProduct]) -> Void)?

    func activate(adaptyApiKey apiKey: String, paywallName: String) {
        adaptyFetcher.activate(adaptyApiKey: apiKey, paywallName: paywallName)
    }

    var defaultProducts: [IAPProduct] = [
        //        WeeklyProduct(), MonthlyProduct()
    ]

    func fetch(completion: @escaping ((Result<[IAPProduct], Error>) -> Void)) {
        fetchAdaptyOrTimeOut(completion: completion)
    }

    func fetchAdaptyOrTimeOut(completion: @escaping ((Result<[IAPProduct], Error>) -> Void)) {
        if adaptyTimeout == .zero {
            // call adaptyFetcher.fetch to prepare products for purchase on selection
            adaptyFetcher.fetch(completion: { _ in })
            // call skFetcher.fetch to load products to display (which we assume is faster than adapty).
            skFetcher.fetch(completion: completion)
            return
        }
        var isAdaptyTimedOut = false
        var isAdaptyFetched = false
        Timer.scheduledTimer(withTimeInterval: adaptyTimeout, repeats: false) { [weak self] _ in
            isAdaptyTimedOut = true
            guard !isAdaptyFetched else { return }
            guard let self else { return }
            skFetcher.fetch(completion: completion)
        }
        adaptyFetcher.fetch { result in
            guard !isAdaptyTimedOut else { return }
            isAdaptyFetched = true
            completion(result)
        }
    }

    func fetchProfile(completion: @escaping ((Result<IAPProfile, Error>) -> Void)) {
        adaptyFetcher.fetchProfile(completion: completion)
    }

    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        adaptyFetcher.restorePurchases(completion: completion)
    }

    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        adaptyFetcher.buy(product: product, completion: completion)
    }

    func logout() {
        adaptyFetcher.logout()
    }

    func identify(_ userID: String) {
        adaptyFetcher.identify(userID)
    }

    func setPlayerId(_ playerId: String?) {
        adaptyFetcher.setPlayerId(playerId)
    }
}
