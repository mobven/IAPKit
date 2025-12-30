//
//  Dashboard.swift
//  API
//
//  Created by Emin Çelikkan on 11.06.2025.
//

import Foundation
import MBAsyncNetworking

public extension API {
    enum Dashboard: AsyncNetworkable {
        case generateConversations(kidID: String)

        public func request() async -> URLRequest {
            switch self {
            case let .generateConversations(kidID):
                await getRequest(
                    url: API.getURL(withPath: "v1/conversation/\(kidID)/generate"),
                    httpMethod: .post
                )
            }
        }
    }
}
