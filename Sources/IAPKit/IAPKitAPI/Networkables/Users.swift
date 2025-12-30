//
//  Users.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import MBAsyncNetworking

public extension API {
    enum Users: AsyncNetworkable {
        case refresh(refreshToken: String)

        public func request() async -> URLRequest {
            switch self {
            case let .refresh(refreshToken):
                var request = await getRequest(
                    url: API.getURL(withPath: "v1/users/refresh"),
                    addBearerToken: false
                )
                if request.allHTTPHeaderFields == nil {
                    request.allHTTPHeaderFields = [:]
                }
                request.allHTTPHeaderFields?.updateValue(
                    refreshToken,
                    forKey: "Authorization"
                )
                return request
            }
        }
    }
}
