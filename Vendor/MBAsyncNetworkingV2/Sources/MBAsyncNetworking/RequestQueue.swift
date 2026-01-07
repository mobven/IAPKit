//
//  RequestQueue.swift
//  API
//
//  Created by Eser Kucuker on 16.03.2025.
//

import Foundation

/// Actor that manages token refresh operations and queues pending requests that require a valid token.
///
/// This actor ensures that if multiple requests detect an invalid token (e.g., 401 Unauthorized),
/// only a single token refresh is triggered, and the rest of the requests wait for the result.
/// It guarantees thread-safe execution and reduces redundant token refresh attempts.
public actor RequestQueueV2 {
    /// Shared singleton instance of the `RequestQueue` for global access.
    public static let shared = RequestQueueV2()

    /// The current ongoing refresh `Task`, if any.
    private var refreshTask: Task<Bool, Error>?

    /// An array of closures representing requests waiting for a token refresh result.
    private var pendingRequests: [(Bool) -> Void] = []

    /// Executes the given async operation after ensuring a valid token is available.
    ///
    /// If a token refresh is already in progress, the operation is queued and will execute once the refresh completes.
    /// If not, a refresh will be initiated.
    ///
    /// - Parameter operation: The async closure to execute once a valid token is confirmed.
    /// - Returns: The result of the provided async operation.
    /// - Throws: `AuthErrorV2.refreshingFailed` if the token refresh fails, or any error thrown by `operation`.
    public func executeAfterTokenRefresh<T: Decodable>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        // If a refresh is already in progress, queue the request
        if let ongoingTask = refreshTask {
            return try await waitForRefreshAndExecute(ongoingTask, operation)
        }

        // Start a new refresh operation
        let refresh = Task {
            try await OAuthManagerV2.shared.authManager.refreshToken()
            return true
        }
        refreshTask = refresh

        defer {
            refreshTask = nil
        }

        do {
            let success = try await refresh.value
            processPendingRequests(success: success)

            if success {
                return try await operation()
            } else {
                throw AuthErrorV2.refreshingFailed
            }
        } catch {
            processPendingRequests(success: false)
            await UserSessionV2.clear()
            throw error
        }
    }

    /// Queues an operation to be executed after an ongoing refresh task completes.
    ///
    /// This function appends the operation to the `pendingRequests` array and waits for the refresh result.
    ///
    /// - Parameters:
    ///   - refreshTask: The existing `Task` responsible for token refresh.
    ///   - operation: The async closure to execute after a successful token refresh.
    /// - Returns: The result of the `operation` if refresh succeeds.
    /// - Throws: `AuthErrorV2.tokenQueueResumeFailed` if refresh fails, or any error thrown by `operation`.
    private func waitForRefreshAndExecute<T: Decodable>(
        _ refreshTask: Task<Bool, Error>,
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
                    continuation.resume(throwing: AuthErrorV2.tokenQueueResumeFailed)
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
