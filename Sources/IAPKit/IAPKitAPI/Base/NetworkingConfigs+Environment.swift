//
//  NetworkingConfigs+Environment.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

public extension NetworkingConfigs {
    enum Environment {
        case development, production

        var isSSLEnabled: Bool {
            switch self {
            case .development: false
            case .production: false // TODO: need certificates
            }
        }

        var baseURL: String {
            switch self {
            case .development: "https://ioslab.online/"
            case .production: "https://ioslab.online/"
            }
        }
    }
}
