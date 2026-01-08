//
//  AsyncNetworkable+URLRequest.swift
//  API
//
//  Created by Eser Kucuker on 16.03.2025.
//

import Foundation

/// Extension that provides helper methods for creating URLRequests with different configurations
extension AsyncNetworkableV2 {
    /// Creates a URLRequest for GET requests with query parameters
    /// - Parameters:
    ///   - queryItems: Dictionary of query parameters to be added to the URL
    ///   - headers: Custom HTTP headers to add to the request
    ///   - url: The base URL for the request
    ///   - httpMethod: HTTP method to use (defaults to GET)
    ///   - addBearerToken: Whether to add an OAuth bearer token to the request
    /// - Returns: A configured URLRequest
    func getRequest(
        queryItems: [String: String] = [:],
        headers: [String: String] = [:],
        url: URL,
        httpMethod: RequestMethodV2 = .get,
        addBearerToken: Bool = true
    ) async -> URLRequest {
        await prepareRequest(
            withUrl: url,
            queryItems: queryItems,
            method: httpMethod,
            contentType: .json,
            headers: headers,
            addBearerToken: addBearerToken
        )
    }

    /// Creates a URLRequest with a JSON body
    /// - Parameters:
    ///   - body: Encodable object to be serialized as JSON in the request body
    ///   - headers: Custom HTTP headers to add to the request
    ///   - url: The base URL for the request
    ///   - httpMethod: HTTP method to use (defaults to POST)
    ///   - addBearerToken: Whether to add an OAuth bearer token to the request
    /// - Returns: A configured URLRequest with JSON body
    func getRequest(
        body: some Encodable,
        headers: [String: String] = [:],
        url: URL,
        httpMethod: RequestMethodV2 = .post,
        addBearerToken: Bool = true
    ) async -> URLRequest {
        var request = await prepareRequest(
            withUrl: url,
            method: httpMethod,
            contentType: .json,
            headers: headers,
            addBearerToken: addBearerToken
        )
        request.httpBody = getBody(body)
        return request
    }

    /// Creates a URLRequest with a JSON body and query parameters
    /// - Parameters:
    ///   - queryItems: Dictionary of query parameters to be added to the URL
    ///   - body: Encodable object to be serialized as JSON in the request body
    ///   - headers: Custom HTTP headers to add to the request
    ///   - url: The base URL for the request
    ///   - httpMethod: HTTP method to use (defaults to POST)
    ///   - addBearerToken: Whether to add an OAuth bearer token to the request
    /// - Returns: A configured URLRequest with JSON body
    func getRequest(
        queryItems: [String: String] = [:],
        body: some Encodable,
        headers: [String: String] = [:],
        url: URL,
        httpMethod: RequestMethodV2 = .post,
        addBearerToken: Bool = true
    ) async -> URLRequest {
        var request = await prepareRequest(
            withUrl: url,
            queryItems: queryItems,
            method: httpMethod,
            contentType: .json,
            headers: headers,
            addBearerToken: addBearerToken
        )
        request.httpBody = getBody(body)
        return request
    }

    /// Creates a URLRequest with form-encoded data
    /// - Parameters:
    ///   - url: The base URL for the request
    ///   - formItems: Dictionary of form parameters to be encoded in the request body
    ///   - headers: Custom HTTP headers to add to the request
    ///   - httpMethod: HTTP method to use (defaults to POST)
    ///   - addBearerToken: Whether to add an OAuth bearer token to the request
    /// - Returns: A configured URLRequest with form data
    func getRequest(
        url: URL,
        formItems: [String: String] = [:],
        headers: [String: String] = [:],
        httpMethod: RequestMethodV2 = .post,
        addBearerToken: Bool = true
    ) async -> URLRequest {
        // TODO: throw exception when an unexpected http method is encountered
        let formData = formItems.map {
            "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .nwURLQueryAllowed) ?? "")"
        }.joined(separator: "&")
        var request = await prepareRequest(
            withUrl: url,
            method: httpMethod,
            contentType: .urlencoded,
            headers: headers,
            addBearerToken: addBearerToken
        )

        request.httpBody = formData.data(using: .utf8)
        return request
    }

    /// Encodes an object to JSON data
    /// - Parameter body: The Encodable object to encode
    /// - Returns: The encoded JSON data or nil if encoding fails
    private func getBody(_ body: some Encodable) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(body)
    }

    /// Creates a multipart form-data request for file uploads
    /// - Parameters:
    ///   - method: HTTP method to use for the upload
    ///   - url: The URL for the upload request
    ///   - parameters: Additional form parameters to include
    ///   - files: Array of files to upload
    ///   - headers: Custom HTTP headers to add to the request
    /// - Returns: A configured URLRequest for multipart file upload
    func uploadRequest(
        method: RequestMethodV2,
        url: URL,
        parameters: [String: String] = [:],
        files: [FileV2] = [],
        headers: [String: String] = [:]
    ) async -> URLRequest {
        var body = Data()
        let boundary = "Boundary-\(UUID().uuidString)"
        let lineBreak = "\r\n"
        let boundaryPrefix = "--\(boundary)\(lineBreak)"
        var timeout = 0.0

        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
            body.appendString("\(value)\(lineBreak)")
        }

        for file in files {
            body.appendString(boundaryPrefix)
            body.appendString(
                "Content-Disposition: form-data; name=\"\(file.name)\";" +
                    "filename=\"\(file.fileNameWithExtension)\"\(lineBreak)"
            )
            body.appendString("Content-Type: \(file.mimeType)\(lineBreak + lineBreak)")
            body.append(file.data)
            body.appendString("\(lineBreak)")
            timeout += Double(file.data.count) * 0.00005
        }
        // if file size is small, there should be a treshold for upload.
        // smaller files reproduces timeout on network.
        if timeout < 30 {
            timeout = 30
        }
        body.appendString("--".appending(boundary.appending("--")))
        var request = await prepareRequest(
            withUrl: url,
            method: .post,
            contentType: .multipartFormData(boundary),
            headers: headers
        )
        request.httpBody = body as Data
        request.timeoutInterval = timeout
        request.httpMethod = method.rawValue
        return request
    }

    /// Helper method to prepare a URLRequest with common configurations
    /// - Parameters:
    ///   - url: The base URL for the request
    ///   - queryItems: Dictionary of query parameters to add to the URL
    ///   - method: HTTP method to use
    ///   - contentType: Content type for the request
    ///   - headers: Custom HTTP headers to add
    ///   - addBearerToken: Whether to add an OAuth bearer token
    /// - Returns: A configured URLRequest
    func prepareRequest(
        withUrl url: URL,
        queryItems: [String: String] = [:],
        method: RequestMethodV2,
        contentType: NetworkContentTypeV2,
        headers: [String: String] = [:],
        addBearerToken: Bool = true
    ) async -> URLRequest {
        let url = url.adding(parameters: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        var headers = headers
        headers.updateValue(contentType.rawValue, forKey: "Content-Type")
        if addBearerToken {
            let token = try? await OAuthManagerV2.shared.authManager.validToken()
            if let token {
                headers.updateValue("Bearer \(token.accessToken)", forKey: "Authorization")
            }
        }
        request.allHTTPHeaderFields = headers
        request.timeoutInterval = SessionV2.shared.timeout.request
        return request
    }
}
