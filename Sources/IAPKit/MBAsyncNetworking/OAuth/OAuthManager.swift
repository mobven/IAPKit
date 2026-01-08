//
//  OAuthManager.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Manager class for OAuth authentication operations
/// Provides access to the application's authentication provider
@MainActor class OAuthManagerV2 {
    /// Shared singleton instance of the OAuthManager
    static let shared: OAuthManagerV2 = .init()

    /// The authentication provider that handles token refresh and validation
    var authManager: OAuthProviderV2 = .init()
}
