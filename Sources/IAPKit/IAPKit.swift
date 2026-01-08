//
//  IAPKit.swift
//  Rink
//
//  Created by Anil Oruc on 29.05.2023.
//

import RxRelay
import RxSwift
import StoreKit
import SwiftUI
import UIKit

typealias ProductIdentifier = String

public protocol IAPKitDelegate: AnyObject {
    func iapKitDidBuy(product: IAPProduct, paywallId: String?)
    func iapKitDidFailToBuy(product: IAPProduct, withError error: Error)
}

public final class IAPKit: NSObject {
    public static let store: IAPKit = .init()
    var networkingConfigs = NetworkingConfigs()

    public static var logLevel: IAPKitLogLevel {
        get { IAPKitLogLevel.logLevel }
        set { IAPKitLogLevel.logLevel = newValue }
    }

    public weak var delegate: IAPKitDelegate?
    public weak var logger: IAPKitLoggable? {
        didSet {
            productFetcher.logger = logger
        }
    }

    private var isBuyProcess: Bool = false
    private let skProducts: BehaviorRelay<IAPProducts>
    private let buyState: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private var paywallId: String = ""

    private var productFetcher = IAPProductFetcher()

    /// Timeout duration in seconds for primary fetcher before falling back to StoreKit
    public var primaryTimeoutDuration: Int {
        get {
            Int(productFetcher.timeout)
        }
        set {
            productFetcher.timeout = TimeInterval(newValue)
        }
    }

    /// Backward compatibility alias for primaryTimeoutDuration
    @available(*, deprecated, renamed: "primaryTimeoutDuration") public var adaptyTimeoutDuration: Int {
        get { primaryTimeoutDuration }
        set { primaryTimeoutDuration = newValue }
    }

    override init() {
        skProducts = BehaviorRelay(value: productFetcher.defaultProducts)
        super.init()
        setupLivePaywallCallbacks()
    }

    private func setupLivePaywallCallbacks() {
        productFetcher.onLivePaywallPurchase = { [weak self] product, paywallId in
            self?.delegate?.iapKitDidBuy(product: product, paywallId: paywallId)
        }
        productFetcher.onLivePaywallFailure = { [weak self] product, error in
            if let product {
                self?.delegate?.iapKitDidFailToBuy(product: product, withError: error)
            }
        }
    }

    /// Activate IAPKit with Adapty provider and custom entitlement ID
    /// - Parameters:
    ///   - apiKey: Adapty API key
    ///   - paywallName: Adapty placement name
    ///   - entitlementId: The entitlement ID to check for premium status (default: "premium")
    public func activate(
        adaptyApiKey apiKey: String, paywallName: String, entitlementId: String = "premium", sdkKey: String
    ) {
        setupNetworking()
        productFetcher.activate(adaptyApiKey: apiKey, paywallName: paywallName, entitlementId: entitlementId)
        registerApp(sdkKey: sdkKey, deviceId: IAPUser.current.deviceId)
    }

    /// Activate IAPKit with RevenueCat provider
    /// - Parameters:
    ///   - apiKey: RevenueCat public API key
    ///   - offeringId: The offering identifier to use (empty string for current offering)
    ///   - entitlementId: The entitlement ID to check for premium status (default: "premium")
    ///   - customerUserId: Optional customer user ID to identify the user during activation
    ///   - completion: Optional completion handler with success/failure result
    public func activate(
        revenueCatApiKey apiKey: String,
        offeringId: String = "",
        entitlementId: String = "premium",
        sdkKey: String
    ) {
        // TODO: @cansu: şöyle bir yapı kurgulayabiliriz.
        // func activate(iapSystem: any IAPActivatable)
        // ve disari bu tipte public struct'lar sunabiliriz, ki bunlardan birisiyle ama tek fonskiyon ile
        // activate cagirilabilsin.
        setupNetworking()
        productFetcher.activate(revenueCatApiKey: apiKey, offeringId: offeringId, entitlementId: entitlementId)
        registerApp(sdkKey: sdkKey, deviceId: IAPUser.current.deviceId)
    }

    // MARK: - Private Helpers

    private func setupNetworking() {
        Task { @MainActor in
            networkingConfigs.setup()
        }
    }

    private func registerApp(sdkKey: String, deviceId: String) {
        Task {
            await performBackendLogin(sdkKey: sdkKey, deviceId: deviceId)
        }
    }

    private func performBackendLogin(sdkKey: String, deviceId: String?) async {
        guard !IAPUser.current.isAuthenticated else {
            logger?.log("IAPKit: Already authenticated, skipping login")
            return
        }

        let registerRequest = RegisterRequest(
            userId: deviceId,
            sdkKey: sdkKey
        )

        do {
            let response: RegisterResponse = try await IAPKitAPI.Auth.register(request: registerRequest)
                .fetchResponse(hasAuthentication: false)

            IAPUser.current.save(tokens: (access: response.accessToken, refresh: response.refreshToken))

            IAPUser.current.sdkKey = sdkKey

            logger?.log("IAPKit: Backend authentication successful")
        } catch {
            logger?.log("IAPKit: Backend authentication failed: \(error.localizedDescription)")
        }
    }

    /// Set the placement (Adapty) or offering ID (RevenueCat)
    public func setPlacement(_ placementName: String) {
        productFetcher.setPlacement(placementName)
    }

    public func logout() {
        productFetcher.logout()
    }

    public func identify(completion: ((Result<Void, Error>) -> Void)? = nil) {
        productFetcher.identify(IAPUser.current.deviceId, completion: completion)
    }

    public func setPlayerId(_ playerId: String?) {
        productFetcher.setPlayerId(playerId)
    }

    public func setFirebaseId(_ id: String?) {
        productFetcher.setFirebaseId(id)
    }

    public func setAdjustDeviceId(_ adjustId: String?) {
        productFetcher.setAdjustDeviceId(adjustId)
    }

    public func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        productFetcher.restorePurchases(completion: completion)
    }

    public func fetchProfile(completion: @escaping ((Result<IAPProfile, Error>) -> Void)) {
        productFetcher.fetchProfile(completion: completion)
    }

    public func fetchPaywallName(completion: @escaping ((String?) -> Void)) {
        productFetcher.fetchPaywallName(completion: completion)
    }

    // MARK: - Paywall UI (RevenueCat only)

    /// Returns a SwiftUI PaywallView for the current placement
    /// Automatically fetches offerings if not already loaded
    /// Only works when using RevenueCat as the IAP provider
    /// - Parameter completion: Completion handler with the paywall view, or nil if not using RevenueCat
    @available(iOS 15.0, *) public func getPaywallView(completion: @escaping (AnyView?) -> Void) {
        productFetcher.getPaywallView(completion: completion)
    }

    /// Returns a UIViewController for the paywall
    /// Automatically fetches offerings if not already loaded
    /// Only works when using RevenueCat as the IAP provider
    /// - Parameters:
    ///   - delegate: Optional PaywallViewControllerDelegate for handling events
    ///   - completion: Completion handler with the view controller, or nil if not using RevenueCat
    @available(iOS 15.0, *)
    public func getPaywallViewController(delegate: Any? = nil, completion: @escaping (UIViewController?) -> Void) {
        productFetcher.getPaywallViewController(delegate: delegate, completion: completion)
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
    @available(*, deprecated, message: "Will be removed in future releases. Use `requestProducts(completion:)` instead")
    @discardableResult func requestProducts() -> BehaviorRelay<IAPProducts> {
        productFetcher.fetch { [weak self] result in
            switch result {
            case let .success(products):
                self?.skProducts.accept(IAPProducts(products: products.products, config: products.config))
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
                logger?.log("Receipt verification failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func handleError(_: Error) {
        buyState.accept(false)
    }

    @available(*, deprecated, message: "Will be removed in future releases. Use `buyProduct(_:completion:)` instead.")
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
