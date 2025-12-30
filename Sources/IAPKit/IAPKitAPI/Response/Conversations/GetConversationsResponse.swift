//
//  GetConversationsResponse.swift
//  API
//
//  Created by Emin Çelikkan on 11.06.2025.
//

import Foundation

public struct GetConversationsResponse: Codable, Sendable {
    public let id: String?
    public let name: String?
    public let order: Int

    public init(id: String? = nil, name: String? = nil, order: Int) {
        self.id = id
        self.name = name
        self.order = order
    }
}
