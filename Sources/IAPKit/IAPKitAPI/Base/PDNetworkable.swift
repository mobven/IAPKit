//
//  PDNetworkable.swift
//  API
//
//  Created by Eser Kucuker on 7.03.2025.
//

import Combine
import Foundation
import MBAsyncNetworking

public extension AsyncNetworkable {
    func getResponse<T: Decodable>(
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
                if T.self is IAPKitEmptyModel.Type {
                    // swiftlint:disable force_cast
                    return IAPKitEmptyModel() as! T
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
