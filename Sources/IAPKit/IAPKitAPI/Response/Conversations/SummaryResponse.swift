//
//  SummaryResponse.swift
//  API
//
//  Created by Emin Çelikkan on 2.07.2025.
//

import Foundation

public struct SummaryResponse: Codable, Sendable {
    public var summary: String?
    public var thingsToDo: [String]?

    public init(summary: String, thingsToDo: [String]) {
        self.summary = summary
        self.thingsToDo = thingsToDo
    }
}
