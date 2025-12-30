//
//  MessagingWebSocket.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation

public final class MessagingWebSocket: BaseWebSocket, @unchecked Sendable {
    public init(conversationID: String, kidID: String) {
        super.init(
            withPath: "v1/messages/listen", headers: [
                "Conversation-ID": conversationID,
                "Kid-ID": kidID
            ]
        )
    }

    override public func start(_ completion: @escaping ((Data) -> Void)) {
        super.start(completion)
    }

    override public func restart() {
        super.restart()
    }

    override public func send(_ data: Data) {
        super.send(data)
    }

    override public func cancel() {
        super.cancel()
    }
}
