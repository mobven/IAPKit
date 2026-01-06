//
//  RegisterResponse.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 5.01.2026.
//

public typealias RegisterResponse = AppResponse<RegisterResponseBody>

public struct RegisterResponseBody: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
}
