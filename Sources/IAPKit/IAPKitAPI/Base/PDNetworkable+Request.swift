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
}
