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
        case signIn(request: SignInRequest)
        case getMe
        case logOut
        case deleteUser

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
            case let .signIn(request):
                return await getRequest(
                    body: request,
                    url: API.getURL(withPath: "v1/users/login"),
                    httpMethod: .post,
                    addBearerToken: false
                )
            case .getMe:
                return await getRequest(
                    url: API.getURL(withPath: "v1/users/me")
                )
            case .logOut:
                return await getRequest(
                    url: API.getURL(withPath: "v1/users/me/logout"),
                    httpMethod: .post
                )
            case .deleteUser:
                return await getRequest(
                    url: API.getURL(withPath: "v1/users/me"),
                    httpMethod: .delete
                )
            }
        }
    }
}
