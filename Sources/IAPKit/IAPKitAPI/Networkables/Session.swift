//
//  Session.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import MBAsyncNetworking

public extension API {
    enum Session: AsyncNetworkable {
        case all(kidID: String)
        case messages(id: String)

        public func request() async -> URLRequest {
            switch self {
            case let .all(kidID):
                await getRequest(url: API.getURL(withPath: "v1/session/kid/\(kidID)"))
            case let .messages(id):
                await getRequest(url: API.getURL(withPath: "v1/session/\(id)/messages"))
            }
        }
    }
}
