//
//  OAuthProvider.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 7.01.2026.
//

import Foundation

/// Delegate protocol for handling token refresh operations
public protocol OAuthProviderDelegate: AnyObject {
    /// Called when a token refresh is required
    /// - Returns: A new OAuth token response or nil if refresh fails
    /// - Throws: Authentication errors if token refresh fails
    func didRequestTokenRefresh() async throws -> OAuthResponse?
}

/// Structure representing OAuth authentication tokens and expiration
public struct OAuthResponse {
    /// The OAuth access token used for authenticating requests
    public let accessToken: String
    /// The OAuth refresh token used to obtain a new access token
    public let refreshToken: String
    /// Time in seconds until the access token expires
    public let expiresIn: Int?

    /// Initialize a new OAuth response
    /// - Parameters:
    ///   - accessToken: The access token
    ///   - refreshToken: The refresh token
    ///   - expiresIn: Expiration time in seconds (optional)
    public init(accessToken: String, refreshToken: String, expiresIn: Int? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

/// Actor that manages OAuth token validation and refresh
public actor OAuthProvider {
    private var refreshTask: Task<OAuthResponse, Error>?
    /// Delegate that handles the actual token refresh implementation
    public weak var delegate: OAuthProviderDelegate?

    public init() {}

    /// Sets the delegate responsible for token refresh
    /// - Parameter delegate: The delegate implementing the token refresh logic
    public func setDelegate(_ delegate: OAuthProviderDelegate) {
        self.delegate = delegate
    }

    /// Gets a valid token, refreshing if necessary
    /// - Returns: A valid OAuth response with tokens
    /// - Throws: Authentication errors if token validation fails
    public func validToken() async throws -> OAuthResponse {
        if let handle = refreshTask {
            return try await handle.value
        }

        // Check if we have a valid access token
        if let accessToken = IAPUser.current.accessToken,
           let refreshToken = IAPUser.current.refreshToken,
           !accessToken.isEmpty {
            return OAuthResponse(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        }

        return try await refreshToken()
    }

    /// Refreshes the OAuth token
    /// - Returns: A new OAuth response with refreshed tokens
    /// - Throws: Authentication errors if token refresh fails
    @discardableResult public func refreshToken() async throws -> OAuthResponse {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task { () throws -> OAuthResponse in
            defer { refreshTask = nil }

            do {
                // Delegate'e haber verip yeni token alıyoruz
                guard let newToken = try await delegate?.didRequestTokenRefresh() else {
                    throw OAuthError.missingToken
                }

                // Yeni token'ı kaydediyoruz
                IAPUser.current.save(tokens: (access: newToken.accessToken, refresh: newToken.refreshToken))
                return newToken

            } catch {
                throw OAuthError.refreshingFailed
            }
        }

        refreshTask = task

        return try await task.value
    }
}
