//
//  OAuthError.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Error types related to OAuth authentication
enum AuthErrorV2: Error {
    /// Returned when no token is available
    case missingToken
    /// Returned when token refresh operation fails
    case refreshingFailed
    /// Returned when the token storage implementation is not available
    case storageNotFound
    /// Returned when a queued request fails to resume after token refresh
    case tokenQueueResumeFailed
}

extension AuthErrorV2: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingToken:
            NSLocalizedString("auth.error.missingToken", bundle: .module, comment: "")
        case .refreshingFailed:
            NSLocalizedString("auth.error.refreshingFailed", bundle: .module, comment: "")
        case .storageNotFound:
            NSLocalizedString("auth.error.storageNotFound", bundle: .module, comment: "")
        case .tokenQueueResumeFailed:
            NSLocalizedString("auth.error.tokenQueueResumeFailed", bundle: .module, comment: "")
        }
    }
}
