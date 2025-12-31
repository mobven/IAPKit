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
            case .production: true
            }
        }

        var baseURL: String {
            switch self {
            case .development: "http://209.38.184.176"
            case .production: "http://209.38.184.176"
            }
        }
    }
}
