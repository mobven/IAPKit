//
//  GetCreditProductsResponse.swift
//  API
//
//  Created by Cansu Özdizlekli on 8.12.2025.
//

import Foundation

public struct CreditProduct: Codable, Sendable, Identifiable {
    public let coins: Int
    public let productId: String

    public var id: String { productId }

    public init(coins: Int, productId: String) {
        self.coins = coins
        self.productId = productId
    }
}

public typealias GetCreditProductsResponse = [CreditProduct]
