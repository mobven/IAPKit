//
//  GetMessagesResponse.swift
//  API
//
//  Created by Eser Kucuker on 18.06.2025.
//
import Foundation

public struct GetMessagesResponse: Codable, Sendable {
    public var deletedMessages: [String]?
    public var pagination: Pagination?
    public var messages: [Message]?

    public struct Message: Codable, Sendable {
        public let id: String?
        public let message: String?
        public let updatedAt: Date?
        public let type: String?
        public let role: Role?
        public let createdAt: Date?
        public let url: String?
        public let remainingCoins: Int?

        public enum Role: String, Codable, Sendable {
            case user, assistant

            var value: MessageType {
                switch self {
                case .assistant: .assistant
                case .user: .user
                }
            }
        }

        public enum MessageType {
            case assistant, user
        }
    }
}
