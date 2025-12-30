//
//  Conversation.swift
//  API
//
//  Created by Emin Çelikkan on 2.07.2025.
//

import Foundation
import MBAsyncNetworking

public extension API {
    enum Conversation: AsyncNetworkable {
        case generateSummary(kidID: String)

        public func request() async -> URLRequest {
            switch self {
            case let .generateSummary(kidID):
                await getRequest(
                    url: API.getURL(withPath: "v1/conversation/\(kidID)/lastSummary")
                )
            }
        }
    }
}
