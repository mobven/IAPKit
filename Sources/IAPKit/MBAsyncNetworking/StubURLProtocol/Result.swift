//
//  Result.swift
//  API
//
//  Created by Eser Kucuker on 18.03.2025.
//

import Foundation

extension StubURLProtocolV2 {
    /// Represents different types of mock responses for network requests
    enum Result {
        /// Successful response with the specified data
        /// You can use `StubURLProtocol.Result.getData()` to read mock data from bundle, easily and inline.
        case success(Data)
        /// Failure response with the specified error
        /// The  actual result of `Networkable.fetch` will be `NetworkingError.underlyingError`.
        case failure(Error)
        /// Failure response with the specified HTTP status code
        /// The  actual result will of `Networkable.fetch` will be `NetworkingError.httpError`.
        case failureStatusCode(Int)
        /// Failure response with the specified error data
        /// You can use `StubURLProtocol.Result.getErrorData()` to read mock data from bundle, easily and inline.
        case failureWithData(Data)
    }
}

extension StubURLProtocolV2.Result {
    /// Creates a success result with data from the specified URL
    /// - Parameter url: URL to load data from
    /// - Returns: A success result with the loaded data
    /// - Note: Will cause a fatal error if the data cannot be loaded
    static func getData(from url: URL?) -> Self {
        guard let fileUrl = url,
              let data = try? Data(contentsOf: fileUrl) else {
            fatalError("Could not load data from specified path: \(url?.absoluteString ?? "")")
        }
        return .success(data)
    }

    /// Creates a success result with data from the specified file path
    /// - Parameter path: File path to load data from
    /// - Returns: A success result with the loaded data
    /// - Note: Will cause a fatal error if the data cannot be loaded
    static func getData(from path: String?) -> Self {
        guard let filePath = path,
              let url = URL(string: "file://\(filePath)"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Could not load data from specified path: \(path ?? "")")
        }
        return .success(data)
    }

    /// Creates a failure result with data from the specified file path
    /// - Parameter path: File path to load error data from
    /// - Returns: A failure with data result containing the loaded data
    /// - Note: Will cause a fatal error if the data cannot be loaded
    static func getErrorData(from path: String?) -> Self {
        guard let filePath = path,
              let url = URL(string: "file://\(filePath)"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Could not load data from specified path: \(path ?? "")")
        }
        return .failureWithData(data)
    }
}
