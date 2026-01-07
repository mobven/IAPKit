//
//  NetworkContentType.swift
//  API
//
//  Created by Eser Kucuker on 10.05.2024.
//

import Foundation

/// Represents Content-Type header values for different types of network requests
public enum NetworkContentTypeV2 {
    /// JSON content type (application/json)
    case json
    /// URL encoded form data (application/x-www-form-urlencoded)
    case urlencoded
    /// Multipart form data for file uploads (multipart/form-data)
    /// - Parameter boundary: The boundary string used to separate parts in the request
    case multipartFormData(String)

    /// The raw string value to use in the Content-Type header
    var rawValue: String {
        switch self {
        case .json: "application/json"
        case .urlencoded: "application/x-www-form-urlencoded"
        case let .multipartFormData(boundary): "multipart/form-data; boundary=\(boundary)"
        }
    }
}
