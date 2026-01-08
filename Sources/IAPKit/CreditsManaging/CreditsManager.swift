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
    func spendCredit(amount: Int) async throws -> Int
}

// MARK: - Implementation

public final class CreditsManager: ObservableObject, CreditsManaging, @unchecked Sendable {
    @Published public private(set) var credits: UserCredit?

    private let creditsService: CreditsAPIServiceProtocol

    public init(creditsService: CreditsAPIServiceProtocol = CreditsAPIService()) {
        self.creditsService = creditsService
    }

    public func refresh() async throws {
        let response = try await creditsService.getCredits()
        await MainActor.run {
            credits = response
        }
    }

    public func claimGiftCoins() async -> Bool {
        do {
            let response = try await creditsService.claimGiftCoins()
            return !response.giftClaimed
        } catch {
            return false
        }
    }

    public func getCreditProducts() async throws -> GetCreditProductsResponse {
        try await creditsService.getCreditProducts()
    }

    public func spendCredit(amount: Int = 1) async throws -> Int {
        let response = try await creditsService.spendCredit(amount: amount)
        await MainActor.run {
            credits = response.remaining
        }
        return response.remaining.totalCoins
    }

    public func checkCreditAndSubsStatus() -> Bool {
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
