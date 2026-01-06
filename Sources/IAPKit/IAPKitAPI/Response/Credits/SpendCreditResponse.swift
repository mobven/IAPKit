//
//  SpendCreditResponse.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 6.01.2026.
//

public struct SpendCreditResponse: Codable, Sendable {
    public let spent: Int
    public let remaining: UserCredit
}
