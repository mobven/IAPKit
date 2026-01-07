//
//  CreditsAPIServiceProtocol.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 30.12.2025.
//

import Foundation

public protocol CreditsAPIServiceProtocol: Sendable {
    func claimGiftCoins() async throws -> ClaimGiftCoinsResponse
    func getCredits() async throws -> GetCreditsResponse
    func getCreditProducts() async throws -> GetCreditProductsResponse
    func spendCredit(amount: Int) async throws -> SpendCreditResponse
}

public struct CreditsAPIService: CreditsAPIServiceProtocol {
    public init() {}

    public func claimGiftCoins() async throws -> ClaimGiftCoinsResponse {
        try await IAPKitAPI.Credits.claimGiftCoins.fetch()
    }

    public func getCredits() async throws -> GetCreditsResponse {
        try await IAPKitAPI.Credits.getCredits.fetch()
    }

    public func getCreditProducts() async throws -> GetCreditProductsResponse {
        try await IAPKitAPI.Credits.getProducts.fetch()
    }
    
    public func spendCredit(amount: Int) async throws -> SpendCreditResponse {
        let request = SpendCreditRequest(amount: amount)
        return try await IAPKitAPI.Credits.spendCredit(request: request).fetch()
    }
}
