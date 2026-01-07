//
//  IAPUser.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//


import Foundation
import MBAsyncNetworking

/// Singleton manager for user session.
public final class IAPUser: ObservableObject {
    private nonisolated(unsafe) static var instance = IAPUser()

    public var keychain: NetworkingStorable = IAPUserStorage()

    /// Current user info
    public static var current: IAPUser {
        instance
    }

    /// Resets user instance.
    public static func clearInstance() {
        instance = IAPUser()
    }

    public var accessToken: String? {
        get { keychain.accessToken }
        set { keychain.accessToken = newValue }
    }

    public var refreshToken: String? {
        get { keychain.refreshToken }
        set { keychain.refreshToken = newValue }
    }

    public var userId: String? {
        get { (keychain as? IAPUserStorage)?.userId }
        set { (keychain as? IAPUserStorage)?.userId = newValue }
    }

    public var sdkKey: String? {
        get { (keychain as? IAPUserStorage)?.sdkKey }
        set { (keychain as? IAPUserStorage)?.sdkKey = newValue }
    }

    public var isAuthenticated: Bool {
        accessToken != nil
    }

    private init() {}

    public func save(tokens: (access: String, refresh: String)) {
        accessToken = tokens.access
        refreshToken = tokens.refresh
    }
}
