//
//  CreditsPackage.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

public struct CreditPackage: Identifiable, Equatable {
    public let id: String
    public let productId: String
    public let creditAmount: Int
    public let localizedPrice: String

    public var creditAmountTitle: String {
        "\(creditAmount) Credits"
    }

    public init(from product: CreditProduct, localizedPrice: String) {
        id = product.productId
        productId = product.productId
        creditAmount = product.coins
        self.localizedPrice = localizedPrice
    }

    public init(id: String, productId: String, creditAmount: Int, localizedPrice: String) {
        self.id = id
        self.productId = productId
        self.creditAmount = creditAmount
        self.localizedPrice = localizedPrice
    }
}
