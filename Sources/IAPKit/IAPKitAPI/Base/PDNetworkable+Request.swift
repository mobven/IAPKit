//
//  PDNetworkable+Request.swift
//  API
//
//  Created by Eser Kucuker on 7.03.2025.
//

import Foundation
import MBAsyncNetworking

public extension AsyncNetworkable {
    func getRequest(url: URL, encodable data: some Encodable, httpMethod: RequestMethod = .post) async -> URLRequest {
        await getRequest(
            body: data,
            url: url,
            httpMethod: httpMethod
        )
    }

    func getRequest(
        url: URL,
        addBearerToken: Bool
    ) async -> URLRequest {
        await getRequest(
            queryItems: [:],
            url: url,
            addBearerToken: addBearerToken
        )
    }

    func getRequest(
        url: URL,
        queryItems: [String: String] = [:],
        headers: [String: String] = [:],
        httpMethod: RequestMethod = .get
    ) async -> URLRequest {
        await getRequest(queryItems: queryItems, headers: headers, url: url, httpMethod: httpMethod)
    }

    func uploadRequest(url: URL, parameters: [String: String] = [:], files: [File] = []) async -> URLRequest {
        await uploadRequest(method: .post, url: url, parameters: parameters, files: files)
    }

    /// Override to inject IAPKit token instead of using UserSession
    /// This prevents IAPKit from using app's UserSession token
    func getRequest(
        queryItems: [String: String] = [:],
        headers: [String: String] = [:],
        url: URL,
        httpMethod: RequestMethod = .get,
        addBearerToken: Bool = true
    ) async -> URLRequest {
        var request = URLRequest(url: url.adding(parameters: queryItems))
        request.httpMethod = httpMethod.rawValue
        var allHeaders = headers
        allHeaders["Content-Type"] = "application/json"

        // Use IAPKit's own token instead of UserSession
        if addBearerToken, let token = IAPUser.current.accessToken {
            allHeaders["Authorization"] = "Bearer \(token)"
        }

        request.allHTTPHeaderFields = allHeaders
        return request
    }

    /// Override to inject IAPKit token for POST requests with body
    /// This prevents IAPKit from using app's UserSession token
    func getRequest(
        body: some Encodable,
        headers: [String: String] = [:],
        url: URL,
        httpMethod: RequestMethod = .post,
        addBearerToken: Bool = true
    ) async -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        var allHeaders = headers
        allHeaders["Content-Type"] = "application/json"

        // Use IAPKit's own token instead of UserSession
        if addBearerToken, let token = IAPUser.current.accessToken {
            allHeaders["Authorization"] = "Bearer \(token)"
        }

        request.allHTTPHeaderFields = allHeaders

        // Encode body
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try? encoder.encode(body)

        return request
    }

    /// Override fetch to handle token refresh independently from UserSession
    func fetchData<T: Decodable>(
        hasAuthentication: Bool = true,
        isRefreshToken: Bool = false
    ) async throws -> T {
        let request = await request()

        do {
            let (data, response) = try await Session.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            switch httpResponse.statusCode {
            case 401:
                // Token expired - log and handle unauthorized response
                let error = NSError(domain: "IAPKit", code: 401, userInfo: ["data": data])
                printErrorLog(error, request: request)

                return try await handleUnauthorizedResponse(
                    hasAuthentication: hasAuthentication,
                    isRefreshToken: isRefreshToken
                )
            case 200...299:
                printResponse(data, request: request)
                if T.self is EmptyModel.Type {
                    return EmptyModel() as! T
                }
                if T.self == Data.self {
                    return data as! T
                }
                return try decoder.decode(T.self, from: data)
            default:
                let error = NSError(domain: "IAPKit", code: httpResponse.statusCode, userInfo: ["data": data])
                printErrorLog(error, request: request)
                throw error
            }
        } catch {
            printErrorLog(error, request: request)
            throw error
        }
    }

    /// Handles 401 Unauthorized responses by attempting to refresh the token
    /// - Parameters:
    ///   - hasAuthentication: Whether authentication is required for this request
    ///   - isRefreshToken: Whether this call is already part of a token refresh attempt
    /// - Returns: The decoded response after handling the authentication issue
    /// - Throws: Authentication errors if token refresh fails
    private func handleUnauthorizedResponse<T: Decodable>(
        hasAuthentication: Bool,
        isRefreshToken: Bool
    ) async throws -> T {
        guard hasAuthentication else {
            throw NSError(
                domain: "IAPKit",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]
            )
        }

        if !isRefreshToken {
            return try await IAPRequestQueue.shared.executeAfterTokenRefresh {
                try await self.fetchData(
                    hasAuthentication: hasAuthentication,
                    isRefreshToken: true
                )
            }
        } else {
            throw NSError(
                domain: "IAPKit",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Token refresh failed"]
            )
        }
    }
}
