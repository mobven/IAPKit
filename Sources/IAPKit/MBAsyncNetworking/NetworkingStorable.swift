//
//  NetworkingStorable.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Protocol for storing and retrieving authentication-related data
/// Implementations should handle the secure storage of tokens and credentials
public protocol NetworkingStorableV2 {
    /// The refresh token used for OAuth authentication
    var refreshToken: String? { get set }

    /// The access token used for OAuth authentication
    var accessToken: String? { get set }
}
