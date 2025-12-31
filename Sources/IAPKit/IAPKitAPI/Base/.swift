//
//  NetworkingConfigs.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import MBAsyncNetworking
import MobKitCore

public final class NetworkingConfigs {
    let networkMonitor = NetworkMonitor()
    var baseDelay: UInt64
    var maxRetryCount: Int

    public init(maxRetryCount: Int = 3, baseDelay: UInt64 = 1_000_000_000) {
        self.maxRetryCount = maxRetryCount
        self.baseDelay = baseDelay
    }

    @MainActor public func setup() {
        UserSession.initialize(with: User.current.keychain)
        NetworkLogsManager.shared.delegate = networkMonitor
        Task {
            await OAuthManager.shared.authManager.setDelegate(self)
        }
    }
}

extension NetworkingConfigs: OAuthProviderDelegate {
    public func didRequestTokenRefresh() async throws -> OAuthResponse? {
        guard let refreshToken = User.current.refreshToken else {
            return nil
        }

        for attempt in 0 ..< maxRetryCount {
            do {
                let response: GetRefreshTokenResponse = try await IAP.Users.refresh(refreshToken: refreshToken)
                    .fetchResponse(hasAuthentication: false)

                return OAuthResponse(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken,
                    expiresIn: -1
                )

            } catch {
                switch error.httpStatusCode {
                case 401:
                    await MainActor.run {
                        NotificationCenter.default.post(name: .navigationOnboarding, object: nil)
                    }
                    throw error
                default:
                    let isLastAttempt = attempt == maxRetryCount - 1
                    if isLastAttempt {
                        await MainActor.run {
                            NotificationCenter.default.post(name: .navigationOnboarding, object: nil)
                        }
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
