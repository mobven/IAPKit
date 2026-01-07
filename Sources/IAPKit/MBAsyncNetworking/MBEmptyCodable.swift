//
//  MBEmptyCodable.swift
//  API
//
//  Created by Rashid Ramazanov on 23.11.2020.
//  Copyright © 2020 Mobven. All rights reserved.
//

import Foundation

/// An empty Codable type used when an API endpoint doesn't return any data
/// or when the response data is not needed
struct MBEmptyCodableV2: Codable {
    /// Default initializer
    init() {}
}
