//
//  CreditsPackage.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

struct CreditPackage: Identifiable, Equatable {
    let id: String
    let productId: String
    let creditAmount: Int
    let localizedPrice: String

    var creditAmountTitle: String {
        "\(creditAmount) Credits"
    }

    init(from product: CreditProduct, localizedPrice: String) {
        id = product.productId
        productId = product.productId
        creditAmount = product.coins
        self.localizedPrice = localizedPrice
    }

    init(id: String, productId: String, creditAmount: Int, localizedPrice: String) {
        self.id = id
        self.productId = productId
        self.creditAmount = creditAmount
        self.localizedPrice = localizedPrice
    }
}
