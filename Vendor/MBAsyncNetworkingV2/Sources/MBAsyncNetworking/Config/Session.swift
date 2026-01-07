//
//  Session.swift
//  API
//
//  Created by Eser Kucuker on 10.01.2025.
//

import Foundation

/// Manages URLSession configuration and handles network session setup
public final class SessionV2 {
    /// Shared singleton instance of the Session
    public static let shared: SessionV2 = .init()

    /// The URLSession used for making network requests
    public var session: URLSession
    /// The delegate handling URLSession callbacks
    public var delegate: URLSessionDelegate

    /// Tasks currently in progress, keyed by identifier
    var tasksInProgress: [String: URLSessionDataTask] = [:]

    /// Timeout configuration for network requests
    var timeout = TimeOutV2(request: 60, resource: 60) {
        didSet {
            session.configuration.timeoutIntervalForRequest = timeout.request
            session.configuration.timeoutIntervalForResource = timeout.resource
        }
    }

    /// SSL certificate paths for certificate pinning
    var certificatePaths: [String] = [] {
        didSet {
            (delegate as? PinnableSessionDelegateV2)?.certificatePaths = certificatePaths
        }
    }

    /// URLSessionConfiguration for the URLSession
    /// Defaults to .default but can be changed to .ephemeral for testing
    var configuration = URLSessionConfiguration.default {
        didSet {
            session = URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
        }
    }

    /// Configures the session to trust all server certificates
    /// Useful for testing environments or when using self-signed certificates
    /// WARNING: Not recommended for production use
    func setServerTrustedURLAuthenticationChallenge() {
        delegate = UntrustedURLSessionDelegateV2()
        session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    /// Configures the session with a custom URLSessionDelegate for authentication challenges
    /// - Parameter challenge: The custom URLSessionDelegate to use
    func setServerTrustedAuthenticationChallenge(_ challenge: URLSessionDelegate) {
        delegate = challenge
        session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    /// Configures the session with a delegate that supports certificate pinning
    func setServerTrustedAuthenticationChallenge() {
        delegate = URLSessionPinnableDelegateAsyncV2()
        session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    /// Initializes the Session with default configuration
    required init() {
        delegate = URLSessionPinnableDelegateAsyncV2()
        session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    /// Enables or disables the stub URL protocol for testing
    /// - Parameter isEnabled: Whether to enable stubbing
    func setStubProtocolEnabled(_ isEnabled: Bool) {
        let configuration = session.configuration
        if isEnabled {
            URLProtocol.registerClass(StubURLProtocolV2.self)
            configuration.protocolClasses = [StubURLProtocolV2.self]
        } else {
            URLProtocol.unregisterClass(StubURLProtocolV2.self)
            configuration.protocolClasses = nil
        }
        session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    /// Structure to define timeout configurations for URLSession
    struct TimeOutV2 {
        /// The timeout interval when waiting for additional data
        var request: TimeInterval
        /// The maximum amount of time that a resource request should be allowed to take
        var resource: TimeInterval
    }
}
