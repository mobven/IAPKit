//
//  NetworkingStorage.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import UIKit

struct NetworkingStorage: NetworkingStorableV2 {
    static let accessTokenKey = "iapkit_access_token"
    static let refreshTokenKey = "iapkit_refresh_token"
    static var deviceIdKey: String {
        "iapkit_" + (Bundle.main.stringFromInfoPlist("KEYCHAIN_DEVICE_KEY") ?? "device_id")
    }

    let keychain: KeychainHelper

    var accessToken: String? {
        get {
            value(forKey: NetworkingStorage.accessTokenKey)
        }
        set {
            save(NetworkingStorage.accessTokenKey, value: newValue)
        }
    }

    var refreshToken: String? {
        get {
            value(forKey: NetworkingStorage.refreshTokenKey)
        }
        set {
            save(NetworkingStorage.refreshTokenKey, value: newValue)
        }
    }

    var deviceId: String {
        get async {
            if let storedDeviceId = value(forKey: NetworkingStorage.deviceIdKey) {
                return storedDeviceId
            }

            let newDeviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            save(NetworkingStorage.deviceIdKey, value: newDeviceId)
            return newDeviceId
        }
    }

    init(keychain: KeychainHelper = KeychainHelper()) {
        self.keychain = keychain
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
}
