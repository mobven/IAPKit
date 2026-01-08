//
//  StubURLProtocol.swift
//  API
//
//  Created by Eser Kucuker on 18.03.2025.
//

import Foundation

/// URLProtocol subclass for mocking network requests in unit tests
/// Acts as a middleware to intercept network requests and provide predefined responses
/// Only works in a test environment (when XCTestConfigurationFilePath is defined)
final class StubURLProtocolV2: URLProtocol {
    /// The result to return when intercepting network requests
    /// Setting this to nil disables the stub protocol
    static var result: Result? {
        didSet {
            if result == nil {
                SessionV2.shared.setStubProtocolEnabled(false)
            } else {
                if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                    SessionV2.shared.setStubProtocolEnabled(true)
                }
            }
        }
    }

    /// Indicates if the stub protocol is enabled (has a result configured)
    static var isEnabled: Bool {
        result != nil
    }
}

extension StubURLProtocolV2 {
    /// Determines if this protocol can handle the given request
    /// - Parameter request: The URLRequest to check
    /// - Returns: true if stubbing is enabled, false otherwise
    override class func canInit(with request: URLRequest) -> Bool {
        isEnabled
    }

    /// Determines if this protocol can handle the given task
    /// - Parameter task: The URLSessionTask to check
    /// - Returns: true if stubbing is enabled, false otherwise
    override class func canInit(with task: URLSessionTask) -> Bool {
        isEnabled
    }

    /// Returns the canonical version of the request
    /// - Parameter request: The URLRequest to canonicalize
    /// - Returns: The same request (no modifications)
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Intercepts the network request and provides the configured mock response
    override func startLoading() {
        guard let result = StubURLProtocolV2.result else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        switch result {
        case let .success(data):
            if let url = request.url,
               let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
            }
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        case let .failureStatusCode(statusCode):
            if let url = request.url,
               let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: Data())
            }
        case let .failureWithData(data):
            if let url = request.url,
               let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
            }
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    /// Called when the loading of a request is cancelled
    override func stopLoading() {
        // Nothing to handle
    }
}
