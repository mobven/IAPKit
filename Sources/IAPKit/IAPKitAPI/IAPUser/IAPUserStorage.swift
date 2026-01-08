//
//  IAPUserStorage.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation
import UIKit

final class IAPUserStorage: NetworkingStorableV2 {
    private let keychain = KeychainHelper()

    private enum Keys {
        static var accessToken: String { "iapkit_accessToken" }
        static var refreshToken: String { "iapkit_refreshToken" }
        static var userId: String { "iapkit_userId" }
        static var sdkKey: String { "iapkit_sdkKey" }
        static var deviceId: String { "iapkit_device_id" }
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

    var userId: String? {
        get {
            value(forKey: Keys.userId)
        }
        set {
            save(Keys.userId, value: newValue)
        }
    }

    var sdkKey: String? {
        get {
            value(forKey: Keys.sdkKey)
        }
        set {
            save(Keys.sdkKey, value: newValue)
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

    // MARK: - Cleanup

    func clearAll() {
        keychain.delete(key: Keys.accessToken)
        keychain.delete(key: Keys.refreshToken)
        keychain.delete(key: Keys.userId)
        keychain.delete(key: Keys.sdkKey)
    }
}
