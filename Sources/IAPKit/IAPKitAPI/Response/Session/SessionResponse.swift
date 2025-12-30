//
//  SessionResponse.swift
//  API
//
//  Prompted by Raşid Ramazanov using Cursor on 13.06.2025.
//

import Foundation

public struct SessionResponse: Codable, Sendable {
    public let id: UUID?
    public let assistantName: String?
    public let summary: String?
    public let createdAt: Date
    public let endDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case assistantName
        case summary
        case createdAt
        case endDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        assistantName = try container.decodeIfPresent(String.self, forKey: .assistantName)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let endDateString = try container.decodeIfPresent(String.self, forKey: .endDate)

        guard let createdAtDate = dateFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Date string does not match format"
            )
        }
        createdAt = createdAtDate
        endDate = endDateString.flatMap { dateFormatter.date(from: $0) }
    }
}
