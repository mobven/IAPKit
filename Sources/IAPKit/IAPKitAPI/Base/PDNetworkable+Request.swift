//
//  PDNetworkable+Request.swift
//  API
//
//  Created by Eser Kucuker on 7.03.2025.
//

import Foundation
import MBAsyncNetworking

public extension AsyncNetworkable {
    private var maxRetryCount: Int { 3 }
    private var baseDelay: UInt64 { 1_000_000_000 }

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
                // Token expired - refresh it
                if !isRefreshToken && hasAuthentication {
                    try await refreshIAPKitToken()
                } else {
                    throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
                }
                throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
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

    private func refreshIAPKitToken() async throws {
        guard let refreshToken = IAPUser.current.refreshToken else {
            throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
        }

        for attempt in 0 ..< maxRetryCount {
            do {
                // Call refresh endpoint
                let response: RefreshTokenResponse = try await IAPKitAPI.Auth.refresh(refreshToken: refreshToken)
                    .fetchData(hasAuthentication: false, isRefreshToken: true)

                // Save new tokens
                IAPUser.current.save(tokens: (access: response.accessToken, refresh: response.refreshToken))
                
                break
            } catch {
                let isLastAttempt = attempt == maxRetryCount - 1

                if isLastAttempt {
                    // All retries failed, attempt to re-register
                    try await reregisterUser()
                    return
                }

                // Exponential backoff: 1s, 2s, 4s, ...
                let delay = baseDelay * UInt64(pow(2.0, Double(attempt)))
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    /// Re-register user when refresh token fails after all retries
    private func reregisterUser() async throws {
        guard let userId = IAPUser.current.userId,
              let sdkKey = IAPUser.current.sdkKey else {
            throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "No registration credentials available"])
        }

        let registerRequest = RegisterRequest(
            userId: userId,
            sdkKey: sdkKey
        )

        let response: RegisterResponse = try await IAPKitAPI.Auth.register(request: registerRequest)
            .fetchData(hasAuthentication: false, isRefreshToken: true)

        guard let body = response.body else {
            throw NSError(domain: "IAPKit", code: 401, userInfo: [NSLocalizedDescriptionKey: "Re-registration failed - empty response body"])
        }

        // Save new tokens
        IAPUser.current.save(tokens: (access: body.accessToken, refresh: body.refreshToken))
    }
}
