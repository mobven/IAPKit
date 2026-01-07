//
//  NetworkLogsDelegate.swift
//  API
//
//  Created by Eser Kucuker on 28.04.2025
//

import Foundation
import OSLog

/// Protocol that defines methods for receiving network logs
/// Apps that use MBAsyncNetworking can implement this protocol to receive network requests and responses
public protocol NetworkLogsDelegateV2: AnyObject {
    /// Called when a network response is received
    /// - Parameters:
    ///   - request: The URLRequest that was made
    ///   - data: The response data received
    ///   - log: The formatted log string
    func didReceiveResponse(request: URLRequest, data: Data?, log: String)

    /// Called when a network error occurs
    /// - Parameters:
    ///   - request: The URLRequest that was made
    ///   - error: The error that occurred
    ///   - log: The formatted log string
    func didReceiveError(request: URLRequest, error: Error?, log: String)
}

/// Optional protocol methods
public extension NetworkLogsDelegateV2 {
    func didReceiveResponse(request: URLRequest, data: Data?, log: String) {}
    func didReceiveError(request: URLRequest, error: Error?, log: String) {}
}
