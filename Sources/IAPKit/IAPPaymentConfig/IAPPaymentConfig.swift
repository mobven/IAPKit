//
//  IAPPaymentConfig.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation

public struct IAPPaymentConfig {
    public let onboardType: IAPOnboardingType
    public let designType: IAPPaywallType
    public let defaultProductIndex: Int
    public let trialToggle: Int
    public let skipPaywall: Bool
    public let products: [IAPPaymentProduct]

    public var defaultProduct: IAPPaymentProduct? {
        return products[safe: defaultProductIndex]
    }

    public var first: IAPPaymentProduct? {
        products.first
    }

    public var second: IAPPaymentProduct? {
        return products[safe: 1]
    }

    public var third: IAPPaymentProduct? {
        return products[safe: 2]
    }

    public var supportsTrial: Bool {
        trialToggle != 0
    }

    public init(
        onboardType: IAPOnboardingType = .single,
        designType: IAPPaywallType = .defaultPaywall,
        defaultProductIndex: Int = .zero,
        trialToggle: Int = .zero,
        skipPaywall: Bool = false,
        products: [IAPPaymentProduct] = []
    ) {
        self.onboardType = onboardType
        self.designType = designType
        self.defaultProductIndex = defaultProductIndex
        self.trialToggle = trialToggle
        self.skipPaywall = skipPaywall
        self.products = products
    }

    init(withParams parameters: [String: Any], productCount: Int = 2) {
        let onboardingType = parameters["onboardType"] as? String
        onboardType = IAPOnboardingType(rawValue: onboardingType ?? "") ?? .default
        let designTypeString = parameters["designType"] as? String
        designType = IAPPaywallType(rawValue: designTypeString ?? "") ?? .defaultPaywall
        defaultProductIndex = ((parameters["defaultProduct"] as? Int) ?? .zero) - 1
        trialToggle = ((parameters["trial_toggle"] as? Int) ?? .zero)
        skipPaywall = (parameters["skip_paywall"] as? Bool) ?? false
        var products: [IAPPaymentProduct] = []
        for productNo in 1 ... productCount {
            let product = IAPPaymentProduct(
                productName: parameters["product\(productNo)_name"] as? String,
                productPrice: parameters["product\(productNo)_price"] as? Double,
                productPriceDivide: parameters["product\(productNo)_secondaryPrice"] as? Double,
                productTimeLabel: parameters["product\(productNo)_secondaryPeriod"] as? String,
                productLocale: parameters["product\(productNo)_period"] as? String,
                productLegalText: parameters["product\(productNo)_legalText"] as? String,
                productButtonTitle: parameters["product\(productNo)_buttonTitle"] as? String,
                productTrailBadge: parameters["product\(productNo)_trailBadge"] as? Bool,
                productPromoBadgeText: parameters["product\(productNo)_promoBadge"] as? String,
                productTrialToggleText: parameters["product\(productNo)_trialToggleText"] as? String,
                hasTrial: trialToggle == productNo
            )
            products.append(product)
        }
        self.products = products
    }
}
