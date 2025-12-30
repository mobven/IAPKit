//
//  User.swift
//  User
//
//  Created by Eser Kucuker on 5.06.2025.
//

import Foundation
import MBAsyncNetworking

/// Singleton manager for user session.
public final class User: ObservableObject {
    private nonisolated(unsafe) static var instance = User()

    public var keychain: NetworkingStorable & UserStorable = UserStorage()

    /// Current user info
    public static var current: User {
        instance
    }

    /// Resets user instance.
    public static func clearInstance() {
        instance = User()
    }

    @Published public var info: UserCodable? {
        didSet {
            if let info {
                keychain.setUserInfo(info)
            }
        }
    }

    public var accessToken: String? {
        get { keychain.accessToken }
        set { keychain.accessToken = newValue }
    }

    public var refreshToken: String? {
        get { keychain.refreshToken }
        set { keychain.refreshToken = newValue }
    }

    public var isAuthenticated: Bool {
        accessToken != nil
    }

    private init() {
        info = keychain.getUserInfo() ?? User.Info()
    }

    public func save(tokens: (access: String, refresh: String)) {
        accessToken = tokens.access
        refreshToken = tokens.refresh
    }

    // swiftlint:disable cyclomatic_complexity
    public func update(
        id: String? = nil,
        fullName: String? = nil,
        email: String? = nil,
        isRegistered: Bool? = nil,
        pushNotificationEnabled: Bool? = false,
        kid: User.Kid? = nil
    ) {
        if let id { info?.id = id }
        if let fullName { info?.fullName = fullName }
        if let email { info?.email = email }
        if let isRegistered { info?.isRegistered = isRegistered }
        if let pushNotificationEnabled { info?.pushNotificationEnabled = pushNotificationEnabled }
        if let kid { info?.kid = kid }
    }

    // swiftlint:enable cyclomatic_complexity

    public func clear() {
        keychain.clearAll()
        info = User.Info()
    }

    /// Replaces the entire user info with a new instance
    /// This ensures no old data persists when updating user data from server
    public func replaceInfo(with newInfo: UserCodable) {
        info = newInfo
    }
}
