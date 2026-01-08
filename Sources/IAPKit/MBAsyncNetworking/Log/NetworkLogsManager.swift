//
//  NetworkLogsManager.swift
//  API
//
//  Created by Eser Kucuker on 28.04.2025
//

import Foundation

/// Singleton class to manage network logs delegation
class NetworkLogsManagerV2 {
    /// Shared instance
    static let shared = NetworkLogsManagerV2()

    /// Delegate for network logs
    weak var delegate: NetworkLogsDelegateV2?

    /// Private initializer for singleton
    private init() {}
}
