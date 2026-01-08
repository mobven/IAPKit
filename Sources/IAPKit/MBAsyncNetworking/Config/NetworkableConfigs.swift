//
//  NetworkableConfigs.swift
//  API
//
//  Created by Eser Kucuker on 10.01.2025.
//

import Foundation

enum NetworkableConfigsV2 {
    case `default`

    /// Sets SSL certificate to be used in SSL pinning.
    /// - parameter certificateResourcePaths: Paths of the certificates for ssl pinning.
    func setCertificatePaths(_ certificateResourcePaths: String...) {
        setCertificatePathArray(certificateResourcePaths)
    }

    /// Sets SSL certificate to be used in SSL pinning.
    /// - parameter certificateResourcePaths: Paths of the certificates for ssl pinning.
    func setCertificatePathArray(_ certificateResourcePaths: [String]) {
        SessionV2.shared.certificatePaths = certificateResourcePaths
    }

    /// Sets timeout for Networkable requests.
    /// - parameter request: The timeout interval to use when waiting for additional data.
    /// - parameter resource: The maximum amount of time that a resource request should be allowed to take.
    func setTimeout(for request: TimeInterval, resource: TimeInterval) {
        SessionV2.shared.timeout = SessionV2.TimeOutV2(request: request, resource: resource)
    }

    /// Configures networking to trust session authentication challenge, even if the certificate is not trusted.
    /// **Apple may reject your application, for this usage. It's on your own responsibility**
    func setServerTrustedURLAuthenticationChallenge() {
        SessionV2.shared.setServerTrustedURLAuthenticationChallenge()
    }

    /// Configures networking delegate and session with passed PinnableSessionDelegate. This method must called before
    /// setCertificatePathArray to set it's certificate paths.
    /// - parameter challenge: PinnableSessionDelegate.
    func setServerTrustedAuthenticationChallenge(_ challenge: PinnableSessionDelegateV2) {
        SessionV2.shared.setServerTrustedAuthenticationChallenge(challenge)
    }

    func setServerTrustedAuthenticationChallenge() {
        SessionV2.shared.setServerTrustedAuthenticationChallenge()
    }

    /// Sets `URLSessionConfiguration` for initiating `URLSession`.
    /// Default value is `URLSessionConfiguration.default` which can be set to `URLSessionConfiguration.ephemeral`.
    /// - Parameter configuration: URLSessionConfiguration.
    func set(configuration: URLSessionConfiguration) {
        SessionV2.shared.configuration = configuration
    }
}
