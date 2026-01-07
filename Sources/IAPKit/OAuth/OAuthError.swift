//
//  OAuthError.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 7.01.2026.
//

import Foundation

/// Error types related to OAuth authentication
public enum OAuthError: Error {
    /// Returned when no token is available
    case missingToken
    /// Returned when token refresh operation fails
    case refreshingFailed
    /// Returned when the token storage implementation is not available
    case storageNotFound
    /// Returned when a queued request fails to resume after token refresh
    case tokenQueueResumeFailed
}

extension OAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingToken:
            return "No token is available for authentication"
        case .refreshingFailed:
            return "Token refresh operation failed"
        case .storageNotFound:
            return "Token storage implementation is not available"
        case .tokenQueueResumeFailed:
            return "Queued request failed to resume after token refresh"
        }
    }
}
