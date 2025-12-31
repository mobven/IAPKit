//
//  NetworkingStorage.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import MBAsyncNetworking
import UIKit

struct NetworkingStorage: NetworkingStorable {
    static let accessTokenKey = "iapkit_accessToken"
    static let refreshTokenKey = "iapkit_refreshToken"
    static let deviceIdKey = "iapkit_deviceId"

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
