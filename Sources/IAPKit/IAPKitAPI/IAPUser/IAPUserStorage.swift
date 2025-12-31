//
//  IAPUserStorage.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation
import MBAsyncNetworking
import UIKit

final class IAPUserStorage: NetworkingStorable {
    private let keychain = KeychainHelper()

    private enum Keys {
        static let accessToken = "iapkit_accessToken"
        static let refreshToken = "iapkit_refreshToken"
        static let userInfo = "userInfo"
        static var deviceId: String {
            "iapkit_" + (Bundle.main.stringFromInfoPlist("KEYCHAIN_DEVICE_KEY") ?? "device_id")
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

    // MARK: - Cleanup

    func clearAll() {
        keychain.delete(key: Keys.accessToken)
        keychain.delete(key: Keys.refreshToken)
    }
}
