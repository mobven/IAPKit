//
//  AsyncNetworkable.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Combine
import Foundation

/// Protocol that defines the main interface for async/await based networking operations.
/// Conforming types need to implement the `request()` method which provides a configured URLRequest.
/// This protocol is extended with multiple capabilities for different networking scenarios.
public protocol AsyncNetworkableV2 {
    /// Returns a configured URLRequest for the network operation.
    /// - Returns: A fully configured URLRequest ready to be executed
    func request() async -> URLRequest
}
