//
//  IAPUser.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

/// Singleton manager for user session.
final class IAPUser: ObservableObject {
    private nonisolated(unsafe) static var instance = IAPUser()

    var keychain: NetworkingStorableV2 = IAPUserStorage()

    /// Current user info
    static var current: IAPUser {
        instance
    }

    /// Resets user instance.
    static func clearInstance() {
        instance = IAPUser()
    }

    var accessToken: String? {
        get { keychain.accessToken }
        set { keychain.accessToken = newValue }
    }

    var refreshToken: String? {
        get { keychain.refreshToken }
        set { keychain.refreshToken = newValue }
    }

    var userId: String? {
        get { (keychain as? IAPUserStorage)?.userId }
        set { (keychain as? IAPUserStorage)?.userId = newValue }
    }

    var sdkKey: String? {
        get { (keychain as? IAPUserStorage)?.sdkKey }
        set { (keychain as? IAPUserStorage)?.sdkKey = newValue }
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    private init() {}

    func save(tokens: (access: String, refresh: String)) {
        accessToken = tokens.access
        refreshToken = tokens.refresh
    }
}
