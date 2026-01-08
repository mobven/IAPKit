//
//  IAPProfile.swift
//  IAPKit
//
//  Created by IAPKit.
//

import Foundation

/// Represents the user's subscription profile
public struct IAPProfile {
    /// Whether the user has an active subscription
    public let isSubscribed: Bool

    /// The expiration date of the subscription, if available
    public let expireDate: Date?

    public init(isSubscribed: Bool, expireDate: Date?) {
        self.isSubscribed = isSubscribed
        self.expireDate = expireDate
    }
}
