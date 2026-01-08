//
//  ClaimGiftCoinsResponse.swift
//  API
//
//  Created by Cansu Özdizlekli on 8.12.2025.
//

import Foundation

public struct ClaimGiftCoinsResponse: Codable, Sendable {
    public let giftCoins: Int
    public let subscriptionCoins: Int
    public let purchaseCoins: Int
    public let totalCoins: Int
    public let giftClaimed: Bool

    public init(
        giftCoins: Int = 0,
        subscriptionCoins: Int = 0,
        purchaseCoins: Int = 0,
        totalCoins: Int = 0,
        giftClaimed: Bool = false
    ) {
        self.giftCoins = giftCoins
        self.subscriptionCoins = subscriptionCoins
        self.purchaseCoins = purchaseCoins
        self.totalCoins = totalCoins
        self.giftClaimed = giftClaimed
    }
}
