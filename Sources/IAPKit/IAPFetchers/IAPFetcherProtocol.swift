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

/// Protocol defining the interface for IAP providers
/// Both Adapty and RevenueCat providers conform to this protocol
public protocol IAPFetcherProtocol: AnyObject {
    /// The type of this provider
    var fetcherType: IAPFetcherType { get }
    
    /// Logger for debugging
    var logger: IAPKitLoggable? { get set }
    
    // MARK: - Lifecycle
    
    /// Activate the provider with the given API key and placement/offering name
    /// - Parameters:
    ///   - apiKey: The API key for the provider
    ///   - placementName: The placement name (Adapty) or offering identifier (RevenueCat)
    ///   - entitlementId: The entitlement identifier to check for premium status
    func activate(apiKey: String, placementName: String, entitlementId: String)
    
    /// Log out the current user
    func logout()
    
    /// Identify the current user with a user ID
    /// - Parameter userID: The user ID to identify
    func identify(_ userID: String)
    
    // MARK: - Products
    
    /// Set the placement/offering name for fetching products
    /// - Parameter placementName: The placement name (Adapty) or offering identifier (RevenueCat)
    func setPlacement(_ placementName: String)
    
    /// Fetch products from the provider
    /// - Parameter completion: Completion handler with the result
    func fetch(completion: @escaping ((Result<IAPProducts, Error>) -> Void))
    
    /// Fetch the paywall/offering name
    /// - Parameter completion: Completion handler with the result
    func fetchPaywall(completion: @escaping ((Result<String, Error>) -> Void))
    
    // MARK: - Profile
    
    /// Fetch the user's profile/subscription status
    /// - Parameter completion: Completion handler with the result
    func fetchProfile(completion: @escaping (Result<IAPProfile, Error>) -> Void)
    
    // MARK: - Purchases
    
    /// Purchase a product
    /// - Parameters:
    ///   - product: The product to purchase
    ///   - completion: Completion handler with the result
    func buy(product: IAPProduct, completion: @escaping ((Result<IAPSubscription, Error>) -> Void))
    
    /// Restore previous purchases
    /// - Parameter completion: Completion handler with the result (true if premium restored)
    func restorePurchases(completion: @escaping ((Result<Bool, Error>) -> Void))
    
    // MARK: - Attribution (Optional)
    
    /// Set the OneSignal player ID for attribution
    func setPlayerId(_ playerId: String?)
    
    /// Set the Firebase App Instance ID for attribution
    func setFirebaseId(_ id: String?)
    
    /// Set the Adjust device ID for attribution
    func setAdjustDeviceId(_ adjustId: String?)
}

// MARK: - Default Implementations for Optional Methods

public extension IAPFetcherProtocol {
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
