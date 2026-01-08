//
//  RequestMethod.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Represents HTTP request methods supported by the networking layer
enum RequestMethodV2: String {
    /// HTTP DELETE method
    case delete = "DELETE"
    /// HTTP GET method
    case get = "GET"
    /// HTTP POST method
    case post = "POST"
    /// HTTP PUT method
    case put = "PUT"
    /// HTTP PATCH method
    case patch = "PATCH"
}
