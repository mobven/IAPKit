//
//  IAPKit.swift
//  Rink
//
//  Created by Anil Oruc on 29.05.2023.
//

import RxRelay
import RxSwift
import StoreKit

typealias ProductIdentifier = String

public protocol IAPKitDelegate: AnyObject {
    func iapKitDidBuy(product: IAPProduct, paywallId: String?)
    func iapKitDidFailToBuy(product: IAPProduct, withError error: Error)
}

public final class IAPKit: NSObject {
    public static let store: IAPKit = .init()

    public weak var delegate: IAPKitDelegate?

    private var isBuyProcess: Bool = false
    private let skProducts: BehaviorRelay<[IAPProduct]>
    private let buyState: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private var paywallId: String = ""

    private var productFetcher = IAPProductFetcher()

    public var adaptyTimeoutDuration: Int {
        get {
            Int(productFetcher.adaptyTimeout)
        }
        set {
            productFetcher.adaptyTimeout = TimeInterval(newValue)
        }
    }

    override init() {
        skProducts = BehaviorRelay(value: productFetcher.defaultProducts)
        super.init()
    }

    public func activate(adaptyApiKey apiKey: String, paywallName: String) {
        productFetcher.activate(adaptyApiKey: apiKey, paywallName: paywallName)
    }

    public func logout() {
        productFetcher.logout()
    }

    public func identify(_ userID: String) {
        productFetcher.identify(userID)
    }

    public func setPlayerId(_ playerId: String?) {
        productFetcher.setPlayerId(playerId)
    }

    public func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        productFetcher.restorePurchases(completion: completion)
    }

    public func fetchProfile(completion: @escaping ((Result<IAPProfile, Error>) -> Void)) {
        productFetcher.fetchProfile(completion: completion)
    }

    public static func getReceiptToken() -> String? {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            do {
                let receiptData = try Data(contentsOf: receiptURL)
                return receiptData.base64EncodedString(options: .endLineWithLineFeed)
            } catch {
                return nil
            }
        }
        return nil
    }
}

public extension IAPKit {
    @discardableResult func requestProducts() -> BehaviorRelay<[IAPProduct]> {
        productFetcher.fetch { [weak self] result in
            switch result {
            case let .success(products):
                self?.skProducts.accept(products.products)
                self?.paywallId = products.paywallId ?? ""
            case let .failure(error):
                self?.handleError(error)
            }
        }
        return skProducts
    }

    func requestProducts(completion: @escaping ((Result<IAPProducts, Error>) -> Void)) {
        productFetcher.fetch { [weak self] result in
            switch result {
            case let .success(products):
                completion(.success(products))
            case let .failure(error):
                self?.handleError(error)
            }
        }
    }

    func verify(completion: @escaping ((Bool) -> Void)) {
        guard !isBuyProcess else {
            completion(false)
            return
        }
        isBuyProcess = true
        productFetcher.fetchProfile { [weak self] result in
            guard let self else { return }
            isBuyProcess = false
            switch result {
            case let .success(result):
                completion(result.isSubscribed)
            case let .failure(error):
                print("Receipt verification failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func handleError(_: Error) {
        buyState.accept(false)
    }

    func buyProduct(_ product: IAPProduct) -> BehaviorRelay<Bool> {
        guard !isBuyProcess else { return buyState }
        isBuyProcess = true
        buyState.accept(false)
        productFetcher.buy(product: product) { [weak self] result in
            self?.isBuyProcess = false
            switch result {
            case .success:
                self?.delegate?.iapKitDidBuy(product: product, paywallId: self?.paywallId)
                self?.buyState.accept(true)
            case let .failure(error):
                self?.delegate?.iapKitDidFailToBuy(product: product, withError: error)
                self?.buyState.accept(false)
            }
        }
        return buyState
    }

    func buyProduct(_ product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void)) {
        guard !isBuyProcess else { return }
        isBuyProcess = true
        productFetcher.buy(product: product) { [weak self] result in
            self?.isBuyProcess = false
            switch result {
            case let .success(subscription):
                self?.delegate?.iapKitDidBuy(product: product, paywallId: self?.paywallId)
                completion(.success(subscription))
            case let .failure(error):
                self?.delegate?.iapKitDidFailToBuy(product: product, withError: error)
                completion(.failure(error))
            }
        }
    }

    func restore() {
        productFetcher.restorePurchases { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(isPremium):
                buyState.accept(isPremium)
            case .failure:
                buyState.accept(false)
            }
        }
    }

    func checkPremium() {
        productFetcher.fetchProfile { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(profile):
                buyState.accept(profile.isSubscribed)
            case .failure:
                buyState.accept(false)
            }
        }
    }
}
