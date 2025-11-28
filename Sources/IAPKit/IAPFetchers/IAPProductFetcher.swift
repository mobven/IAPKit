//
//  IAPProductFetcher.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Foundation
import StoreKit

protocol IAPProductFetchable {
    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void))
}

final class IAPProductFetcher {
    private let adaptyFetcher: AdaptyFetcher
    private var skFetcher: StoreKitFetcher

    var adaptyTimeout: TimeInterval = 5

    init() {
        adaptyFetcher = AdaptyFetcher()
        skFetcher = StoreKitFetcher()
        adaptyFetcher.logger = logger
    }

    var logger: IAPKitLoggable? {
        didSet {
            adaptyFetcher.logger = logger
        }
    }

    var completion: (([IAPProduct]) -> Void)?

    func activate(adaptyApiKey apiKey: String, paywallName: String) {
        adaptyFetcher.activate(adaptyApiKey: apiKey, paywallName: paywallName)
    }
    
    func setPlacement(_ placementName: String) {
        adaptyFetcher.setPlacement(placementName)
    }

    var defaultProducts: IAPProducts = .init(products: [])
    //        WeeklyProduct(), MonthlyProduct()

    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void)) {
        fetchAdaptyOrTimeOut(completion: completion)
    }

    func fetchPaywallName(completion: @escaping ((String?) -> Void)) {
        adaptyFetcher.fetchPaywall { result in
            switch result {
            case let .success(paywallName):
                completion(paywallName)
            case let .failure(error):
                completion(error.localizedDescription)
            }
        }
    }

    func fetchAdaptyOrTimeOut(completion: @escaping ((Result<IAPProducts, Error>) -> Void)) {
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
        let group = DispatchGroup()
        var adaptyResult: Result<Bool, Error>?
        var storeKitResult: Result<Bool, Error>?
        
        // Call Adapty restore
        group.enter()
        adaptyFetcher.restorePurchases { result in
            adaptyResult = result
            group.leave()
        }
        
        // Call StoreKit restore
        group.enter()
        skFetcher.restorePurchases { result in
            storeKitResult = result
            group.leave()
        }
        
        // Wait for both to complete
        group.notify(queue: .main) {
            let adaptySuccess = (try? adaptyResult?.get()) ?? false
            let storeKitSuccess = (try? storeKitResult?.get()) ?? false
            
            // If either returns true, return true
            if adaptySuccess || storeKitSuccess {
                completion(.success(true))
                return
            }
            
            // Check if any service returned an error
            if case let .failure(error) = adaptyResult ?? storeKitResult {
                completion(.failure(error))
                return
            }
            
            // Both services returned false and no error was provided
            completion(.success(false))
        }
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
    
    func setFirebaseId(_ id: String?) {
        adaptyFetcher.setFirebaseId(id)
    }
    
    func setAdjustDeviceId(_ adjustId: String?) {
        adaptyFetcher.setAdjustDeviceId(adjustId)
    }
}
