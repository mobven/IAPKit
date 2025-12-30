//
//  CreditsManager.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 30.12.2025.
//

import Foundation

// MARK: - Protocol

public protocol CreditsManaging: AnyObject, Sendable {
    var credits: UserCredit? { get }
    func refresh() async throws
    func claimGiftCoins() async -> Bool
    func getCreditProducts() async throws -> GetCreditProductsResponse
    func checkCreditAndSubsStatus() -> Bool
}

// MARK: - Implementation

public final class CreditsManager: ObservableObject, CreditsManaging, @unchecked Sendable {
    @Published private(set) var credits: UserCredit?

    private let creditsService: CreditsAPIServiceProtocol

    init(creditsService: CreditsAPIServiceProtocol = CreditsAPIService()) {
        self.creditsService = creditsService
    }

    func refresh() async throws {
        let response = try await creditsService.getCredits()
        await MainActor.run {
            credits = response
        }
    }

    func claimGiftCoins() async -> Bool {
        do {
            let response = try await creditsService.claimGiftCoins()
            return !response.giftClaimed
        } catch {
            return false
        }
    }

    func getCreditProducts() async throws -> GetCreditProductsResponse {
        try await creditsService.getCreditProducts()
    }

    func checkCreditAndSubsStatus() -> Bool {
        guard let credits else { return true }

        // 1. Gift coin varsa subscription olmadan da contente erişebilir.
        if credits.giftCoins > 0 {
            return false
        }

        // Subscription yoksa engelle
        guard credits.isSubscriptionActive else {
            return true
        }

        // Subscription var ama coin yoksa engelle
        if credits.totalCoins <= 0 {
            return true
        }

        return false
    }
}
