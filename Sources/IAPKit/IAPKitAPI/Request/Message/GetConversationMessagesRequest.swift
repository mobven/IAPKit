//
//  GetConversationMessagesRequest.swift
//  API
//
//  Created by Eser Kucuker on 18.06.2025.
//

import Foundation

public struct GetConversationMessagesRequest: Codable {
    let conversationId: String
    let lastUpdateDate: String
    let pagination: Pagination

    public init(
        conversationId: String,
        lastUpdateDate: String,
        pagination: Pagination,
    ) {
        self.conversationId = conversationId
        self.lastUpdateDate = lastUpdateDate
        self.pagination = pagination
    }

    func body() -> [String: String] {
        var query: [String: String] = [:]
        query["conversationId"] = conversationId
        query["lastUpdateDate"] = lastUpdateDate
        return query
    }

    func getParams() -> [String: String] {
        var query: [String: String] = [:]
        query["per"] = String(pagination.per)
        query["page"] = String(pagination.page)
        return query
    }
}

public struct Pagination: Codable, Sendable {
    public var per: Int
    public var page: Int
    public var total: Int

    public init(per: Int, page: Int, total: Int = 0) {
        self.per = per
        self.page = page
        self.total = total
    }
}
