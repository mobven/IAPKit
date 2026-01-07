//
//     Networkable+Pinning.swift
//  API
//
//  Created by Eser Kucuker on 11.01.2025.
//

import Foundation
import Security

public protocol PinnableSessionDelegateV2: URLSessionDelegate {
    var certificatePaths: [String] { get set }
}

public final class URLSessionPinnableDelegateAsyncV2: NSObject, PinnableSessionDelegateV2 {
    public var certificatePaths: [String] = []

    public init(certificatePaths: [String] = []) {
        self.certificatePaths = certificatePaths
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    )
        async -> (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) {
        guard let serverCertificate = getServerCertificate(forChallenge: challenge) else {
            return (.cancelAuthenticationChallenge, nil)
        }

        let serverPublicKeys = serverCertificate.trust.certificates.publicKeys
        for certificatePath in certificatePaths {
            if let localCertificateData = try? Data(contentsOf: URL(fileURLWithPath: certificatePath)) as CFData?,
               let localCertificate = SecCertificateCreateWithData(nil, localCertificateData),
               let localPublicKey = localCertificate.publicKey {
                if serverPublicKeys.contains(localPublicKey) {
                    return (.useCredential, URLCredential(trust: serverCertificate.trust))
                }
            }
        }

        if certificatePaths.count == 0 {
            // No SSL pinning. Performing default handling.
            return (.performDefaultHandling, nil)
        } else {
            // SSL pinning could not succeed with given certificates. Cancelling authentication.
            return (.cancelAuthenticationChallenge, nil)
        }
    }

    private func getServerCertificate(
        forChallenge challenge: URLAuthenticationChallenge
    ) -> (data: CFData, trust: SecTrust)? {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return nil
        }

        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error),
              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return nil
        }

        let serverCertificateData = SecCertificateCopyData(serverCertificate)
        return (serverCertificateData, serverTrust)
    }
}

extension URLSessionPinnableDelegateAsyncV2: URLSessionTaskDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        logTask(task, didFinishCollecting: metrics)
    }
}

public extension PinnableSessionDelegateV2 {
    func logTask(_ task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // Session.shared.networkLogMonitoringDelegate?.logTask(task: task, didFinishCollecting: metrics)
    }
}

class UntrustedURLSessionDelegateV2: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    )
        async -> (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            (.useCredential, URLCredential(trust: serverTrust))
        } else {
            (.cancelAuthenticationChallenge, nil)
        }
    }
}
