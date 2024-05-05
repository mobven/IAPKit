//
//  IAPProducts.swift
//
//
//  Created by Eser Kucuker on 19.03.2024.
//

import Foundation

public struct IAPProducts {
    public let products: [IAPProduct]
    public let config: [String: Any]?
    public let paywallId: String?
    public let productConfigs: IAPPaymentConfig?

    init(
        products: [IAPProduct],
        config: [String : Any]? = nil,
        paywallId: String? = nil
    ) {
        self.products = products
        self.config = config
        self.paywallId = paywallId
        self.productConfigs = .init(withParams: config ?? [:])
    }
}

extension IAPProducts: Equatable {
    public static func == (lhs: IAPProducts, rhs: IAPProducts) -> Bool {
        guard lhs.products == rhs.products else {
            return false
        }
        if let lhsConfig = lhs.config, let rhsConfig = rhs.config {
            guard NSDictionary(dictionary: lhsConfig).isEqual(to: rhsConfig) else {
                return false
            }
        } else if lhs.config != nil || rhs.config != nil {
            return false
        }
        return lhs.paywallId == rhs.paywallId
    }
}
