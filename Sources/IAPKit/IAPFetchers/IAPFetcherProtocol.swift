//
//  IAPFetcherProtocol.swift
//  IAPKit
//
//  Created by IAPKit on 22.12.2024.
//

import Foundation

/// Enum representing the available IAP provider types
public enum IAPFetcherType: String {
    case adapty
    case revenueCat
    case storeKit
}

// MARK: - ProductFetchable

/// Base protocol for fetching products - all fetchers support this
/// StoreKit, Adapty, and RevenueCat all conform to this protocol
public protocol ProductFetchable: AnyObject {
    /// The type of this provider
    var fetcherType: IAPFetcherType { get }

    /// Logger for debugging
    var logger: IAPKitLoggable? { get set }

    /// Fetch products from the provider
    /// - Parameter completion: Completion handler with the result
    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void))

    /// Fetch the user's profile/subscription status
    /// - Parameter completion: Completion handler with the result
    func fetchProfile(completion: @escaping (Result<IAPProfile, Error>) -> Void)

    /// Purchase a product
    /// - Parameters:
    ///   - product: The product to purchase
    ///   - completion: Completion handler with the result
    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void))

    /// Restore previous purchases
    /// - Parameter completion: Completion handler with the result (true if premium restored)
    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void))
}

// MARK: - ManagedIAPProvider

/// Extended protocol for managed IAP providers (Adapty, RevenueCat)
/// These providers require activation and support user management features
/// that native StoreKit doesn't provide
public protocol ManagedIAPProvider: ProductFetchable {
    // MARK: - Lifecycle

    /// Activate the provider with the given API key and placement ID
    /// - Parameters:
    ///   - apiKey: The API key for the provider
    ///   - placementName: The placement ID used to fetch the appropriate offering
    ///   - entitlementId: The entitlement identifier to check for premium status
    ///   - customerUserId: Optional customer user ID to identify the user during activation
    ///   - completion: Optional completion handler with success/failure result
    func activate(
        apiKey: String,
        placementName: String,
        entitlementId: String,
        customerUserId: String?,
        completion: ((Result<Void, Error>) -> Void)?
    )

    /// Log out the current user
    func logout()

    /// Identify the current user with a user ID
    /// - Parameters:
    ///   - userID: The user ID to identify
    ///   - completion: Optional completion handler with success/failure result
    func identify(_ userID: String, completion: ((Result<Void, Error>) -> Void)?)

    // MARK: - Placement

    /// Set the placement ID for fetching products
    /// - Parameter placementName: The placement ID used to fetch the appropriate offering
    func setPlacement(_ placementName: String)

    /// Fetch the paywall/offering name
    /// - Parameter completion: Completion handler with the result
    func fetchPaywall(completion: @escaping ((Result<String, Error>) -> Void))

    // MARK: - Attribution

    /// Set the OneSignal player ID for attribution
    func setPlayerId(_ playerId: String?)

    /// Set the Firebase App Instance ID for attribution
    func setFirebaseId(_ id: String?)

    /// Set the Adjust device ID for attribution
    func setAdjustDeviceId(_ adjustId: String?)
}

// MARK: - Default Implementations

public extension ManagedIAPProvider {
    func setPlayerId(_ playerId: String?) {
        // Default empty implementation
    }

    func setFirebaseId(_ id: String?) {
        // Default empty implementation
    }

    func setAdjustDeviceId(_ adjustId: String?) {
        // Default empty implementation
    }

    func fetchPaywall(completion: @escaping ((Result<String, Error>) -> Void)) {
        // Default empty implementation
        completion(.success(""))
    }
}

// MARK: - Backward Compatibility

/// Typealias for backward compatibility
/// New code should use ManagedIAPProvider or ProductFetchable directly
public typealias IAPFetcherProtocol = ManagedIAPProvider
