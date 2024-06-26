//
//  IAPPaymentProduct.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation
import StoreKit

public extension IAPPaymentConfig {
    struct IAPPaymentProduct: Equatable {
        public var productName: String?
        public var productPrice: Double?
        public var productPriceDivide: Double?
        public var productTimeLabel: String?
        public var productLocale: String?
        public var productLegalText: String?
        public var productButtonTitle: String?
        public var productTrailBadge: Bool?
        public var productPromoBadgeText: String?
        public var productTrialToggleText: String?
        public var hasTrial: Bool

        public var hasSubtitle: Bool {
            !(productPriceDivide == nil || productPriceDivide == 0)
        }
    }
}
