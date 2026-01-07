//
//  Auth.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation
import MBAsyncNetworking

public extension IAPKitAPI {
    enum Auth: AsyncNetworkable {
        case refresh(refreshToken: String)
        case register(request: RegisterRequest)
        
        public func request() async -> URLRequest {
            switch self {
            case let .refresh(refreshToken):
                var request = await getRequest(
                    queryItems: [:],
                    url: IAPKitAPI.getURL(withPath: "api/v1/users/refresh"),
                    httpMethod: .post,
                    addBearerToken: false
                )
                if request.allHTTPHeaderFields == nil {
                    request.allHTTPHeaderFields = [:]
                }
                request.allHTTPHeaderFields?.updateValue(
                    "Bearer \(refreshToken)",
                    forKey: "Authorization"
                )
                return request
            case let .register(request):
                return await getRequest(
                    body: request,
                    url: IAPKitAPI.getURL(withPath: "api/v1/users/register"),
                    httpMethod: .post,
                    addBearerToken: false
                )
            }
        }
    }
}
