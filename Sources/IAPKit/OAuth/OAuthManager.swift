//
//  OAuthManager.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 7.01.2026.
//

import Foundation

/// Manager class for OAuth authentication operations
/// Provides access to the application's authentication provider
@MainActor public class OAuthManager {
    /// The authentication provider that handles token refresh and validation
    public var authProvider: OAuthProvider = .init()

    public init() {}
}
