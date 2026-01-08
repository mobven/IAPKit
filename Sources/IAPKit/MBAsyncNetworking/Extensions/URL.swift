//
//  URL.swift
//  Networking
//
//  Created by Rasid Ramazanov on 25.11.2019.
//  Copyright © 2019 LeanScale. All rights reserved.
//

import Foundation

/// Extensions for the URL type to assist with network requests
extension URL {
    /// Initializes a URL with a string, causing a fatal error if parsing fails
    /// - Parameter string: The URL string to parse
    /// - Returns: A valid URL
    /// - Note: Will cause a fatal error if the string cannot be parsed as a URL
    init(forceString string: String) {
        guard let url = URL(string: string) else { fatalError("Could not init URL '\(string)'") }
        self = url
    }

    /// Returns a URL with query parameters added
    /// - Parameter parameters: Dictionary of query parameters to add
    /// - Returns: A new URL with the query parameters appended
    func adding(parameters: [String: String]) -> URL {
        guard parameters.count > 0 else { return self }
        var queryItems: [URLQueryItem] = []
        for parameter in parameters {
            queryItems.append(URLQueryItem(name: parameter.key, value: parameter.value))
        }
        return adding(queryItems: queryItems)
    }

    /// Returns a URL with the specified query items added
    /// - Parameter queryItems: Array of URLQueryItem to add
    /// - Returns: A new URL with the query items appended
    /// - Note: Will cause a fatal error if the URL cannot be properly constructed
    private func adding(queryItems: [URLQueryItem]) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString) else {
            fatalError("Could not create URLComponents using URL: '\(absoluteURL)'")
        }
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            fatalError("Could not create URL")
        }
        return url
    }
}
