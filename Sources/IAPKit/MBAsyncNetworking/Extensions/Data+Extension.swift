//
//  Data+Extension.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Extensions for Data type to assist with network operations
extension Data {
    /// Appends a string to the data object, encoding as UTF-8
    /// - Parameter string: The string to append
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
