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

    init(products: [IAPProduct], config: [String : Any]? = nil) {
        self.products = products
        self.config = config
    }
}
