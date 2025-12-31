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
        case login(request: LoginRequest)
        
        public func request() async -> URLRequest {
            switch self {
            case let .refresh(refreshToken):
                var request = await getRequest(
                    url: IAPKitAPI.getURL(withPath: "v1/users/refresh"),
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
            case let .login(request):
                return await getRequest(
                    body: request,
                    url: IAPKitAPI.getURL(withPath: "v1/users/login"),
                    httpMethod: .post,
                    addBearerToken: false
                )
            }
        }
    }
}
