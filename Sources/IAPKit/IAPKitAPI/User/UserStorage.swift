//
//  UserStorage.swift
//  User
//
//  Created by Eser Kucuker on 5.06.2025.
//

import Foundation
import MBAsyncNetworking
import UIKit

public protocol UserStorable {
    // User Info
    func setUserInfo(_ info: UserCodable)
    func getUserInfo() -> UserCodable?

    // Cleanup
    func clearAll()
}

final class UserStorage: NetworkingStorable, UserStorable {
    private let keychain = KeychainHelper()

    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let userInfo = "userInfo"
        static var deviceId: String {
            Bundle.main.infoForKey("KEYCHAIN_DEVICE_KEY") ?? "device-id"
        }
    }

    var accessToken: String? {
        get {
            value(forKey: Keys.accessToken)
        }
        set {
            save(Keys.accessToken, value: newValue)
        }
    }

    var refreshToken: String? {
        get {
            value(forKey: Keys.refreshToken)
        }
        set {
            save(Keys.refreshToken, value: newValue)
        }
    }

    var deviceId: String {
        get async {
            if let storedDeviceId = value(forKey: Keys.deviceId) {
                return storedDeviceId
            }

            let newDeviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            save(Keys.deviceId, value: newDeviceId)
            return newDeviceId
        }
    }

    func save(_ key: String, value: String?) {
        if let value {
            keychain.save(key, value: value)
        } else {
            keychain.delete(key: key)
        }
    }

    func value(forKey key: String) -> String? {
        keychain.read(key: key)
    }

    // MARK: - User Info

    func setUserInfo(_ info: UserCodable) {
        guard let data = try? JSONEncoder().encode(info) else { return }
        keychain.save(Keys.userInfo, data: data)
    }

    func getUserInfo() -> UserCodable? {
        guard let data = keychain.readData(key: Keys.userInfo) else { return nil }
        return try? JSONDecoder().decode(User.Info.self, from: data)
    }

    // MARK: - Cleanup

    func clearAll() {
        keychain.delete(key: Keys.accessToken)
        keychain.delete(key: Keys.refreshToken)
        keychain.delete(key: Keys.userInfo)
    }
}
