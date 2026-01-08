//
//  PurchaseCreditRequest.swift
//  API
//
//  Created by Cansu Özdizlekli on 8.12.2025.
//

import Foundation

public struct PurchaseCreditRequest: Codable, Sendable {
    public let productId: String

    public init(productId: String) {
        self.productId = productId
    }
}
