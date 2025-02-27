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
    public var hasNotificationToggle: Bool = false // uses for reminder notification on timeline paywall
    public let offerType: IAPOfferType
    public let upperCtaText: String?
    public let discountRate: Double?
    public let products: [IAPPaymentProduct]

    public var defaultProduct: IAPPaymentProduct? {
        products[safe: defaultProductIndex]
    }

    public var first: IAPPaymentProduct? {
        products.first
    }

    public var second: IAPPaymentProduct? {
        products[safe: 1]
    }

    // Key varsa boş olsa bile tick gösterilmeli, key olmazsa gösterilmemeli şeklinde kural konuldu
    public var hasUpperCtaText: Bool {
        upperCtaText != nil
    }

    public var third: IAPPaymentProduct? {
        products[safe: 2]
    }
    
    public var fourth: IAPPaymentProduct? {
        products[safe: 3]
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
        offerType: IAPOfferType = .noOffer,
        upperCtaText: String? = nil,
        discountRate: Double? = nil,
        products: [IAPPaymentProduct] = []
    ) {
        self.onboardType = onboardType
        self.designType = designType
        self.defaultProductIndex = defaultProductIndex
        self.trialToggle = trialToggle
        self.skipPaywall = skipPaywall
        self.offerType = offerType
        self.upperCtaText = upperCtaText
        self.discountRate = discountRate
        self.products = products
    }

    init(withParams parameters: [String: Any], productCount: Int = 2) {
        let onboardingType = parameters["onboardType"] as? String
        onboardType = IAPOnboardingType(rawValue: onboardingType ?? "") ?? .default
        let designTypeString = parameters["designType"] as? String
        designType = IAPPaywallType(rawValue: designTypeString ?? "") ?? .defaultPaywall
        upperCtaText = parameters["upper_cta_button"] as? String
        defaultProductIndex = ((parameters["defaultProduct"] as? Int) ?? .zero) - 1
        trialToggle = ((parameters["trial_toggle"] as? Int) ?? .zero)
        hasNotificationToggle = ((parameters["notification_toggle"] as? Bool) ?? false)
        let offerTypeString = parameters["offerType"] as? String
        offerType = IAPOfferType(rawValue: offerTypeString ?? "") ?? .noOffer
        let discountRateString = parameters["discount_rate"] as? String ?? "1.42"
        discountRate = Double(discountRateString) ?? 1.42 // 10/7 şeklinde hesaplanmalı product tarafında
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
                productTrialBadge: parameters["product\(productNo)_trialBadge"] as? String,
                productPromoBadgeText: parameters["product\(productNo)_promoBadge"] as? String,
                productTrialToggleText: parameters["product\(productNo)_trialToggleText"] as? String,
                hasTrial: trialToggle == productNo
            )
            products.append(product)
        }
        self.products = products
    }
}
