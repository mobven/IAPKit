//
//  NetworkingConfigs.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

public final class NetworkingConfigs {
    let networkMonitor = NetworkMonitor()
    var baseDelay: UInt64
    var maxRetryCount: Int

    #if DEBUG
    static var environment: Environment = .development
    #else
    static var environment: Environment = .production
    #endif

    public init(maxRetryCount: Int = 3, baseDelay: UInt64 = 1_000_000_000) {
        self.maxRetryCount = maxRetryCount
        self.baseDelay = baseDelay
    }

    @MainActor public func setup() {
        UserSessionV2.initialize(with: IAPUser.current.keychain)
        NetworkLogsManagerV2.shared.delegate = networkMonitor
        Task {
            await OAuthManagerV2.shared.authManager.setDelegate(self)
        }
    }

    private func setSslPinnig() {
        if Self.environment.isSSLEnabled {
            NetworkableConfigsV2.default.setCertificatePathArray(IAPKitAPI.getCertificatePaths())
        } else {
            NetworkableConfigsV2.default.setServerTrustedURLAuthenticationChallenge()
        }
    }
}

extension NetworkingConfigs: OAuthProviderDelegateV2 {
    func didRequestTokenRefresh() async throws -> OAuthResponseV2? {
        guard let refreshToken = IAPUser.current.refreshToken else {
            return nil
        }

        for attempt in 0 ..< maxRetryCount {
            do {
                let response: RefreshTokenResponse = try await IAPKitAPI.Auth.refresh(refreshToken: refreshToken)
                    .fetchResponse(hasAuthentication: false, isRefreshToken: true)

                let accessToken = response.accessToken
                let newRefreshToken = response.refreshToken

                await MainActor.run {
                    IAPUser.current.save(tokens: (access: accessToken, refresh: newRefreshToken))
                }

                let oAuthResponse = OAuthResponseV2(
                    accessToken: accessToken,
                    refreshToken: newRefreshToken,
                    expiresIn: .zero
                )

                await UserSessionV2.shared.save(oAuthResponse)

                return OAuthResponseV2(
                    accessToken: accessToken,
                    refreshToken: newRefreshToken,
                    expiresIn: .zero
                )

            } catch {
                let isLastAttempt = attempt == maxRetryCount - 1

                if isLastAttempt {
                    // After max retries failed, try to re-register
                    return try await performReRegister()
                }

                // Exponential backoff: 1s, 2s, 4s, ...
                let delay = baseDelay * UInt64(pow(2.0, Double(attempt)))
                try? await Task.sleep(nanoseconds: delay)
            }
        }
        return nil
    }

    private func performReRegister() async throws -> OAuthResponseV2? {
        let userId = IAPUser.current.deviceId
        guard let sdkKey = IAPUser.current.sdkKey else {
            return nil
        }

        let registerRequest = RegisterRequest(
            userId: userId,
            sdkKey: sdkKey
        )

        let response: RegisterResponse = try await IAPKitAPI.Auth.register(request: registerRequest)
            .fetchResponse(hasAuthentication: false)

        await MainActor.run {
            IAPUser.current.save(tokens: (access: response.accessToken, refresh: response.refreshToken))
        }

        let oAuthResponse = OAuthResponseV2(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: .zero
        )

        await UserSessionV2.shared.save(oAuthResponse)

        return oAuthResponse
    }
}
