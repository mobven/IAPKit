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
        public var productTrialBadge: String?
        public var productPromoBadgeText: String?
        public var productTrialToggleText: String?
        public var hasTrial: Bool

        public var hasSubtitle: Bool {
            !(productPriceDivide == nil || productPriceDivide == 0)
        }

        // Public initializer tanımı:
        public init(
            productName: String? = nil,
            productPrice: Double? = nil,
            productPriceDivide: Double? = nil,
            productTimeLabel: String? = nil,
            productLocale: String? = nil,
            productLegalText: String? = nil,
            productButtonTitle: String? = nil,
            productTrialBadge: String? = nil,
            productPromoBadgeText: String? = nil,
            productTrialToggleText: String? = nil,
            hasTrial: Bool
        ) {
            self.productName = productName
            self.productPrice = productPrice
            self.productPriceDivide = productPriceDivide
            self.productTimeLabel = productTimeLabel
            self.productLocale = productLocale
            self.productLegalText = productLegalText
            self.productButtonTitle = productButtonTitle
            self.productTrialBadge = productTrialBadge
            self.productPromoBadgeText = productPromoBadgeText
            self.productTrialToggleText = productTrialToggleText
            self.hasTrial = hasTrial
        }
    }
}
