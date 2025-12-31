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
    let networkMonitor = NetworkMonitor()
    var baseDelay: UInt64
    var maxRetryCount: Int
    #if DEBUG
    var environment: Environment = .development
    #else
    var environment: Environment = .production
    #endif
    var onUnAuthorized: (() -> Void)?

    public init(maxRetryCount: Int = 3, baseDelay: UInt64 = 1_000_000_000) {
        self.maxRetryCount = maxRetryCount
        self.baseDelay = baseDelay
    }

    @MainActor public func setup() {
        UserSession.initialize(with: IAPUser.current.keychain)
        NetworkLogsManager.shared.delegate = networkMonitor
        Task {
            await OAuthManager.shared.authManager.setDelegate(self)
        }
    }
    
    public func setupOAuth2(onUnAuthorized: (() -> Void)?) {
        self.onUnAuthorized = onUnAuthorized
    }

    private func setSslPinnig() {
        if environment.isSSLEnabled {
            NetworkableConfigs.default.setCertificatePathArray(IAPKitAPI.getCertificatePaths())
        } else {
            NetworkableConfigs.default.setServerTrustedURLAuthenticationChallenge()
        }
    }
}

extension NetworkingConfigs: OAuthProviderDelegate {
    public func didRequestTokenRefresh() async throws -> OAuthResponse? {
        guard let refreshToken = IAPUser.current.refreshToken else {
            onUnAuthorized?()
            return nil
        }

        for attempt in 0 ..< maxRetryCount {
            do {
                let response: RefreshTokenResponse = try await IAPKitAPI.Auth.refresh(refreshToken: refreshToken)
                    .getResponse(hasAuthentication: false)

                return OAuthResponse(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken,
                    expiresIn: -1
                )
            } catch {
                switch error.httpStatusCode {
                case 401:
                    throw error
                default:
                    let isLastAttempt = attempt == maxRetryCount - 1
                    if isLastAttempt {
                        throw error
                    }
                    // Exponential backoff: 1s, 2s, 4s, ...
                    let delay = baseDelay * UInt64(pow(2.0, Double(attempt)))
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }

        return nil
    }
}
