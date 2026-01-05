//
//  RefreshTokenResponse.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

public struct RefreshTokenResponse: Codable, Sendable {
    public let refreshToken: String
    public let accessToken: String
}
