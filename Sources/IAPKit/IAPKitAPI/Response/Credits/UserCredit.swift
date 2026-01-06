//
//  UserCredit.swift
//  API
//
//  Created by Cansu Özdizlekli on 8.12.2025.
//

import Foundation

// MARK: - Type Aliases

public typealias GetCreditsResponse = UserCredit

public struct UserCredit: Codable, Sendable {
    public let giftCoins: Int
    public let subscriptionCoins: Int
    public let purchaseCoins: Int
    public let totalCoins: Int
    public let giftClaimed: Bool
    public let subscriptionPackageName: String?
    public let subscriptionRenewPeriod: String?
    public let subscriptionPotentialCoins: Int?
    public let isSubscriptionActive: Bool

    public init(
        giftCoins: Int = 0,
        subscriptionCoins: Int = 0,
        purchaseCoins: Int = 0,
        totalCoins: Int = 0,
        giftClaimed: Bool = false,
        subscriptionPackageName: String? = nil,
        subscriptionRenewPeriod: String? = nil,
        subscriptionPotentialCoins: Int? = nil,
        isSubscriptionActive: Bool = false
    ) {
        self.giftCoins = giftCoins
        self.subscriptionCoins = subscriptionCoins
        self.purchaseCoins = purchaseCoins
        self.totalCoins = totalCoins
        self.giftClaimed = giftClaimed
        self.subscriptionPackageName = subscriptionPackageName
        self.subscriptionRenewPeriod = subscriptionRenewPeriod
        self.subscriptionPotentialCoins = subscriptionPotentialCoins
        self.isSubscriptionActive = isSubscriptionActive
    }
}
