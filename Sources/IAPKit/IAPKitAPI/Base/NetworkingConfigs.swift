//
//  NetworkingConfigs.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation
import MBAsyncNetworking
import MobKitCore

public final class NetworkingConfigs {
    public static let shared = NetworkingConfigs()

    let networkMonitor = NetworkMonitor()
    var baseDelay: UInt64
    var maxRetryCount: Int
    #if DEBUG
    var environment: Environment = .development
    #else
    var environment: Environment = .production
    #endif

    public init(maxRetryCount: Int = 1, baseDelay: UInt64 = 1_000_000_000) {
        self.maxRetryCount = maxRetryCount
        self.baseDelay = baseDelay
    }

    @MainActor public func setup() {
        NetworkLogsManager.shared.delegate = networkMonitor
    }

    private func setSslPinnig() {
        if environment.isSSLEnabled {
            NetworkableConfigs.default.setCertificatePathArray(IAPKitAPI.getCertificatePaths())
        } else {
            NetworkableConfigs.default.setServerTrustedURLAuthenticationChallenge()
        }
    }
}
