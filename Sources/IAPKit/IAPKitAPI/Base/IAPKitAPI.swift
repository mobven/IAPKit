//
//  IAPKitAPI.swift
//  IAPKitAPI
//
//  Created by Eser Kucuker on 7.03.2025.
//

import Foundation

public enum IAPKitAPI {
    static func getURL(withPath path: String) -> URL {
        let baseURL = NetworkingConfigs.shared.environment.baseURL
        guard let url = URL(string: "\(baseURL)\(path)") else {
            fatalError("Could not prepare url")
        }
        return url
    }

    static func getCertificatePaths() -> [String] {
        var paths: [String] = []
        for certificate in certificateNames {
            guard let path = Bundle.main.path(forResource: certificate, ofType: "der") else {
                fatalError("Could not find certificate file in the bundle!")
            }
            paths.append(path)
        }
        return paths
    }

    static var certificateNames: [String] {
        // TODO: sertifika eklenecek
        let certificates = (Bundle.main.stringFromInfoPlist("SSL_CERTIFICATE_NAMES") ?? "").components(separatedBy: ",")
        return certificates
    }
}
