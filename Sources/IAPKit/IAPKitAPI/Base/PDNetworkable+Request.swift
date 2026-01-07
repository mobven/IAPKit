//
//  PDNetworkable+Request.swift
//  API
//
//  Created by Eser Kucuker on 7.03.2025.
//

import Foundation

public extension AsyncNetworkableV2 {
    func getRequest(url: URL, encodable data: some Encodable, httpMethod: RequestMethodV2 = .post) async -> URLRequest {
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
        httpMethod: RequestMethodV2 = .get
    ) async -> URLRequest {
        await getRequest(queryItems: queryItems, headers: headers, url: url, httpMethod: httpMethod)
    }

    func uploadRequest(url: URL, parameters: [String: String] = [:], files: [FileV2] = []) async -> URLRequest {
        await uploadRequest(method: .post, url: url, parameters: parameters, files: files)
    }
}
