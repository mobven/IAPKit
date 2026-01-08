//
//  SpendCreditRequest.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 6.01.2026.
//

import Foundation

public struct SpendCreditRequest: Codable, Sendable {
    public let amount: Int

    public init(amount: Int) {
        self.amount = amount
    }
}
