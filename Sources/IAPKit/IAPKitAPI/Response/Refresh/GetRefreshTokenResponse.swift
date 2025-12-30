//
//  GetRefreshTokenResponse.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

public struct GetRefreshTokenResponse: Codable, Sendable {
    public let refreshToken: String
    public let pushNotificationEnabled: Bool
    public let id: String
    public let accessToken: String
    public let nameSurname: String
}
