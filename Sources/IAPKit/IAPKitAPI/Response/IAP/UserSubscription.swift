//
//  UserSubscription.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 5.01.2026.
//

import Foundation

/// Response model for IAP buy and restore endpoints
/// Returned from `/api/v1/iap/buy` and `/api/v1/iap/restore`
public struct UserSubscription: Codable, Sendable {
    public let hasAccess: Bool
    public let isActive: Bool
    public let productId: String?
    public let autoRenewStatus: Bool?
    public let isTrialPeriod: Bool?
    public let expiresAt: String?

    public init(
        hasAccess: Bool = false,
        isActive: Bool = false,
        productId: String? = nil,
        autoRenewStatus: Bool? = nil,
        isTrialPeriod: Bool? = nil,
        expiresAt: String? = nil
    ) {
        self.hasAccess = hasAccess
        self.isActive = isActive
        self.productId = productId
        self.autoRenewStatus = autoRenewStatus
        self.isTrialPeriod = isTrialPeriod
        self.expiresAt = expiresAt
    }
}

// MARK: - Convenience Properties

public extension UserSubscription {
    /// Parsed expiration date
    var expirationDate: Date? {
        guard let expiresAt else { return nil }
        return ISO8601DateFormatter().date(from: expiresAt)
    }

    /// Whether the subscription has expired
    var isExpired: Bool {
        guard let expirationDate else { return true }
        return expirationDate < Date()
    }
}
