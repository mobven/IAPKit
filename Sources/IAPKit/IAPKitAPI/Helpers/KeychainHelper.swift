//
//  KeychainHelper.swift
//  IAPKit
//
//  Created by IAPKit on 30.12.2025.
//

import Foundation
import Security

final class KeychainHelper {
    init() {}

    func save(_ key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(key, data: data)
    }

    func save(_ key: String, data: Data) {
        // Delete any existing item
        delete(key: key)

        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Add item to keychain
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("KeychainHelper: Failed to save item with key '\(key)'. Status: \(status)")
        }
    }

    func read(key: String) -> String? {
        guard let data = readData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func readData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else if status != errSecItemNotFound {
            print("KeychainHelper: Failed to read item with key '\(key)'. Status: \(status)")
        }

        return nil
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            print("KeychainHelper: Failed to delete item with key '\(key)'. Status: \(status)")
        }
    }
}
