//
//  AsyncNetworkable+Data.swift
//  API
//
//  Created by Eser Kucuker on 7.03.2025.
//

import Combine
import Foundation

/// Extension that provides the main data fetching functionality for the networking layer
extension AsyncNetworkableV2 {
    /// Fetches and decodes data from the network into the specified Decodable type
    /// - Parameters:
    ///   - hasAuthentication: Indicates if the request requires authentication (defaults to true)
    ///   - isRefreshToken: Flag to indicate if this is a token refresh attempt (defaults to false)
    /// - Returns: The decoded object of type T
    /// - Throws: Network errors, authentication errors, or decoding errors
    func fetch<T: Decodable>(
        hasAuthentication: Bool = true,
        isRefreshToken: Bool = false
    ) async throws -> T {
        let request = await request()
        do {
            let (data, response) = try await SessionV2.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            switch httpResponse.statusCode {
            case 401:
                return try await handleUnauthorizedResponse(
                    hasAuthentication: hasAuthentication,
                    isRefreshToken: isRefreshToken
                )
            case 200 ... 299:
                printResponse(data, request: request)
                do {
                    if T.self is MBEmptyCodableV2.Type {
                        // swiftlint:disable force_cast
                        return MBEmptyCodableV2() as! T
                        // swiftlint:enable force_cast
                    }
                    if T.self == Data.self {
                        // swiftlint:disable force_cast
                        return data as! T
                        // swiftlint:enable force_cast
                    }
                    let response = try decoder.decode(T.self, from: data)
                    return response
                } catch {
                    let error = NSError(
                        domain: "",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
                    )
                    printErrorLog(error, request: request)
                    throw error
                }
            default:
                let error = NSError(
                    domain: "MBAsyncNetworking",
                    code: httpResponse.statusCode,
                    userInfo: ["MBAsyncNetworkingErrorData": data]
                )
                printErrorLog(error, request: request)
                throw error
            }
        } catch {
            printErrorLog(error, request: request)
            throw error
        }
    }

    // swiftformat:disable all
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
          domain: "MBAsyncNetworking",
          code: 401,
          userInfo: [
            NSLocalizedDescriptionKey: "unauthorized"
          ]
        )
      }
      if !isRefreshToken {
        return try await RequestQueueV2.shared.executeAfterTokenRefresh {
          try await fetch(
            hasAuthentication: hasAuthentication,
            isRefreshToken: true
          )
        }
      } else {
        await UserSessionV2.clear()
        throw NSError(
          domain: "MBAsyncNetworking",
          code: -3,
          userInfo: [
            NSLocalizedDescriptionKey: "Tokenization could not be completed because, " +
            "access_token and/or exires_in is not in expected format."
          ]
        )
      }
    }
    // swiftformat:enable all
}
