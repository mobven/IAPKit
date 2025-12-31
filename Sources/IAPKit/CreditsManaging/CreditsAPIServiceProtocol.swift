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
}

public struct CreditsAPIService: CreditsAPIServiceProtocol {
    public init() {}

    public func claimGiftCoins() async throws -> ClaimGiftCoinsResponse {
        try await IAPKitAPI.Credits.claimGiftCoins.getResponse()
    }

    public func getCredits() async throws -> GetCreditsResponse {
        try await IAPKitAPI.Credits.getCredits.getResponse()
    }

    public func getCreditProducts() async throws -> GetCreditProductsResponse {
        try await IAPKitAPI.Credits.getProducts.getResponse()
    }
}
