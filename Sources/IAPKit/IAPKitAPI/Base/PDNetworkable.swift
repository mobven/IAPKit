//
//  PDNetworkable.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 7.01.2026.
//

import Foundation

extension AsyncNetworkableV2 {
    func fetchResponse<T: Decodable>(
        hasAuthentication: Bool = true,
        isRefreshToken: Bool = false
    ) async throws -> T {
        do {
            let response: AppResponse<T> = try await fetch(
                hasAuthentication: hasAuthentication, isRefreshToken: isRefreshToken
            )
            if let value = response.body {
                return value
            } else {
                if T.self is EmptyModel.Type {
                    // swiftlint:disable force_cast
                    return EmptyModel() as! T
                    // swiftlint:enable force_cast
                } else {
                    throw NSError.generic
                }
            }
        } catch {
            throw error
        }
    }
}
