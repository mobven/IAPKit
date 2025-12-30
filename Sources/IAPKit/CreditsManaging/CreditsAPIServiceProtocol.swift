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
    func purchaseCredits(productId: String) async throws -> PurchaseCreditsResponse
}

struct CreditsAPIService: CreditsAPIServiceProtocol {
    func claimGiftCoins() async throws -> ClaimGiftCoinsResponse {
        try await API.Credits.claimGiftCoins.fetchResponse()
    }

    func getCredits() async throws -> GetCreditsResponse {
        try await API.Credits.getCredits.fetchResponse()
    }

    func getCreditProducts() async throws -> GetCreditProductsResponse {
        try await API.Credits.getProducts.fetchResponse()
    }

    func purchaseCredits(productId: String) async throws -> PurchaseCreditsResponse {
        let request = PurchaseCreditRequest(productId: productId)
        return try await API.Credits.purchase(request: request).fetchResponse()
    }
}
