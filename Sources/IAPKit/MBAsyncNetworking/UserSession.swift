//
//  UserSession.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Manages the current user's session and authentication state
/// This class is a singleton that must be initialized with a storage implementation
@MainActor public final class UserSessionV2: ObservableObject {
    private static var instance: UserSessionV2?
    private var storage: NetworkingStorableV2

    /// Initializes the shared UserSession instance with the specified storage implementation
    /// Must be called before accessing the shared instance
    /// - Parameter storage: The storage implementation for persisting authentication data
    public class func initialize(with storage: NetworkingStorableV2) {
        instance = try? UserSessionV2(storage: storage)
    }

    /// The shared singleton instance of UserSession
    /// Will cause a fatal error if accessed before initialization
    public class var shared: UserSessionV2 {
        guard let instance else {
            fatalError("UserSessionV2 must be initialized with storage before accessing shared instance")
        }
        return instance
    }

    /// The current authenticated user, if any
    public private(set) var user: OAuthResponseV2?

    /// Saves the user's authentication data to storage and updates the current user
    /// - Parameter user: The OAuth response containing authentication tokens
    public func save(_ user: OAuthResponseV2) {
        storage.accessToken = user.accessToken
        storage.refreshToken = user.refreshToken
        self.user = user
    }

    /// Private initializer to enforce singleton pattern
    /// - Parameter storage: The storage implementation to use
    /// - Throws: May throw if there are issues accessing storage
    private init(storage: NetworkingStorableV2) throws {
        self.storage = storage
        if let accessToken = storage.accessToken, let refreshToken = storage.refreshToken {
            user = OAuthResponseV2(accessToken: accessToken, refreshToken: refreshToken, expiresIn: 0)
        }
    }

    /// The current access token, if available
    public var token: String? {
        storage.accessToken
    }

    /// Indicates whether a user is currently logged in
    public var isLoggedIn: Bool {
        storage.accessToken != nil
    }

    /// Clears the user session and triggers a logout notification
    public class func clear() {
        instance?.storage.accessToken = nil
        instance?.storage.refreshToken = nil
        instance?.user = nil
    }
}

/// Structure representing a signed-in user
public struct SignedUserV2 {
    /// The OAuth access token
    public var accessToken: String?
    /// The OAuth refresh token
    public var refreshToken: String?
    /// The token type (usually "Bearer")
    public var tokenType: String?
    /// The number of seconds until the token expires
    public var expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "iapkit_access_token"
        case refreshToken = "iapkit_refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}
