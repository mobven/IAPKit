//
//  Message.swift
//  API
//
//  Created by Eser Kucuker on 18.06.2025.
//

import Foundation
import MBAsyncNetworking

public extension API {
    enum Message: AsyncNetworkable {
        case getMessageByConversationID(request: GetConversationMessagesRequest)

        public func request() async -> URLRequest {
            switch self {
            case let .getMessageByConversationID(request):
                await getRequest(
                    queryItems: request.getParams(),
                    body: request.body(),
                    url: API.getURL(withPath: "v1/messages"),
                    httpMethod: .post
                )
            }
        }
    }
}
