//
//  RequestQueue.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 7.01.2026.
//

import Foundation

/// Actor that manages token refresh operations and queues pending requests that require a valid token.
///
/// This actor ensures that if multiple requests detect an invalid token (e.g., 401 Unauthorized),
/// only a single token refresh is triggered, and the rest of the requests wait for the result.
/// It guarantees thread-safe execution and reduces redundant token refresh attempts.
public actor IAPRequestQueue {
    /// Shared singleton instance of the `IAPRequestQueue` for global access.
    public static let shared = IAPRequestQueue()

    /// The current ongoing refresh `Task`, if any.
    private var refreshTask: Task<Void, Error>?

    /// An array of closures representing requests waiting for a token refresh result.
    private var pendingRequests: [(Bool) -> Void] = []

    /// Maximum number of retry attempts for refresh token
    private let maxRetryCount: Int = 3

    /// Base delay for exponential backoff (1 second in nanoseconds)
    private let baseDelay: UInt64 = 1_000_000_000

    /// Executes the given async operation after ensuring a valid token is available.
    ///
    /// If a token refresh is already in progress, the operation is queued and will execute once the refresh completes.
    /// If not, a refresh will be initiated with retry logic and fallback to re-registration.
    ///
    /// - Parameter operation: The async closure to execute once a valid token is confirmed.
    /// - Returns: The result of the provided async operation.
    /// - Throws: Authentication errors if token refresh fails, or any error thrown by `operation`.
    public func executeAfterTokenRefresh<T: Decodable>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        // If a refresh is already in progress, queue the request
        if let ongoingTask = refreshTask {
            return try await waitForRefreshAndExecute(ongoingTask, operation)
        }

        // Start a new refresh operation
        let refresh = Task {
            try await performTokenRefreshWithRetry()
        }
        refreshTask = refresh

        defer {
            refreshTask = nil
        }

        do {
            try await refresh.value
            processPendingRequests(success: true)
            return try await operation()
        } catch {
            processPendingRequests(success: false)
            throw error
        }
    }

    /// Performs token refresh with retry logic and fallback to re-registration
    private func performTokenRefreshWithRetry() async throws {
        for attempt in 0 ..< maxRetryCount {
            do {
                // Read fresh refresh token on each attempt to pick up any updates
                guard let refreshToken = IAPUser.current.refreshToken else {
                    throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
                }
                
                // Call refresh endpoint without auth handling to prevent recursive loops
                let response: RefreshTokenResponse = try await IAPKitAPI.Auth.refresh(refreshToken: refreshToken)
                    .fetchData(hasAuthentication: false, isRefreshToken: true)

                // Save new tokens
                IAPUser.current.save(tokens: (access: response.accessToken, refresh: response.refreshToken))

                return
            } catch {
                let isLastAttempt = attempt == maxRetryCount - 1

                if isLastAttempt {
                    // All retries failed, attempt to re-register
                    try await reregisterUser()
                    return
                }

                // Exponential backoff: 1s, 2s, 4s, ...
                let delay = baseDelay * UInt64(pow(2.0, Double(attempt)))
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    /// Re-register user when refresh token fails after all retries
    private func reregisterUser() async throws {
        guard let userId = IAPUser.current.userId,
              let sdkKey = IAPUser.current.sdkKey else {
            throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "No registration credentials available"])
        }

        let registerRequest = RegisterRequest(
            userId: userId,
            sdkKey: sdkKey
        )

        // Call register endpoint without auth handling to prevent recursive loops
        let response: RegisterResponse = try await IAPKitAPI.Auth.register(request: registerRequest)
            .fetchData(hasAuthentication: false, isRefreshToken: true)

        guard let body = response.body else {
            throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "Re-registration failed - empty response body"])
        }

        // Save new tokens
        IAPUser.current.save(tokens: (access: body.accessToken, refresh: body.refreshToken))
    }

    /// Queues an operation to be executed after an ongoing refresh task completes.
    ///
    /// This function appends the operation to the `pendingRequests` array and waits for the refresh result.
    ///
    /// - Parameters:
    ///   - refreshTask: The existing `Task` responsible for token refresh.
    ///   - operation: The async closure to execute after a successful token refresh.
    /// - Returns: The result of the `operation` if refresh succeeds.
    /// - Throws: Authentication errors if refresh fails, or any error thrown by `operation`.
    private func waitForRefreshAndExecute<T: Decodable>(
        _ refreshTask: Task<Void, Error>,
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            pendingRequests.append { success in
                if success {
                    Task {
                        do {
                            let result = try await operation()
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token refresh failed"]))
                }
            }
        }
    }

    /// Processes all queued operations after a token refresh attempt has completed.
    ///
    /// Each operation is resumed with a boolean indicating whether the token refresh was successful.
    ///
    /// - Parameter success: `true` if the token was refreshed successfully, `false` otherwise.
    private func processPendingRequests(success: Bool) {
        let requests = pendingRequests
        pendingRequests = []
        for request in requests {
            request(success)
        }
    }
}
