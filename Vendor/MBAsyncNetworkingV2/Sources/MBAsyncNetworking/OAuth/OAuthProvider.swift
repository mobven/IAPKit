//
//  OAuthProvider.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Delegate protocol for handling token refresh operations
public protocol OAuthProviderDelegateV2: AnyObject {
    /// Called when a token refresh is required
    /// - Returns: A new OAuth token response or nil if refresh fails
    /// - Throws: Authentication errors if token refresh fails
    func didRequestTokenRefresh() async throws -> OAuthResponseV2?
}

/// Structure representing OAuth authentication tokens and expiration
public struct OAuthResponseV2 {
    /// The OAuth access token used for authenticating requests
    public let accessToken: String
    /// The OAuth refresh token used to obtain a new access token
    public let refreshToken: String
    /// Time in seconds until the access token expires
    public let expiresIn: Int

    /// Initialize a new OAuth response
    /// - Parameters:
    ///   - accessToken: The access token
    ///   - refreshToken: The refresh token
    ///   - expiresIn: Expiration time in seconds
    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

/// Actor that manages OAuth token validation and refresh
public actor OAuthProviderV2 {
    private var refreshTask: Task<OAuthResponseV2, Error>?
    /// Delegate that handles the actual token refresh implementation
    public weak var delegate: OAuthProviderDelegateV2?

    /// Sets the delegate responsible for token refresh
    /// - Parameter delegate: The delegate implementing the token refresh logic
    public func setDelegate(_ delegate: OAuthProviderDelegateV2) {
        self.delegate = delegate
    }

    /// Gets a valid token, refreshing if necessary
    /// - Returns: A valid OAuth response with tokens
    /// - Throws: Authentication errors if token validation fails
    public func validToken() async throws -> OAuthResponseV2 {
        if let handle = refreshTask {
            return try await handle.value
        }

        guard let user = await UserSessionV2.shared.user else {
            return try await refreshToken()
        }

        if !user.accessToken.isEmpty {
            return user
        }

        return try await refreshToken()
    }

    /// Refreshes the OAuth token
    /// - Returns: A new OAuth response with refreshed tokens
    /// - Throws: Authentication errors if token refresh fails
    @discardableResult public func refreshToken() async throws -> OAuthResponseV2 {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task { () throws -> OAuthResponseV2 in
            defer { refreshTask = nil }

            do {
                // Delegate'e haber verip yeni token alıyoruz
                guard let newToken = try await delegate?.didRequestTokenRefresh() else {
                    throw AuthErrorV2.missingToken
                }

                // Yeni token'ı kaydediyoruz
                await UserSessionV2.shared.save(newToken)
                return newToken

            } catch {
                throw AuthErrorV2.missingToken
            }
        }

        refreshTask = task

        return try await task.value
    }
}
