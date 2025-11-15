//
//  IAPPaymentConfig.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation

public struct IAPPaymentConfig {
    public let onboardType: any IAPOnboardingType
    public let designType: any IAPPaywallType
    public let defaultProductIndex: Int
    public let trialToggle: Int
    public let skipPaywall: Bool
    public var hasNotificationToggle: Bool = false // uses for reminder notification on timeline paywall
    public let notificationToggleState: Bool // uses for initial toggle state on timeline paywall
    public let offerType: any IAPOfferType
    public let offerSkip: Bool
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
        onboardType: some IAPOnboardingType = OnboardingType.default,
        designType: some IAPPaywallType = PaywallType.defaultPaywall,
        defaultProductIndex: Int = .zero,
        trialToggle: Int = .zero,
        skipPaywall: Bool = false,
        offerType: some IAPOfferType = OfferType.noOffer,
        offerSkip: Bool = false,
        upperCtaText: String? = nil,
        discountRate: Double? = nil,
        products: [IAPPaymentProduct] = [],
        notificationToggleState: Bool = false
    ) {
        self.onboardType = onboardType
        self.designType = designType
        self.defaultProductIndex = defaultProductIndex
        self.trialToggle = trialToggle
        self.skipPaywall = skipPaywall
        self.offerType = offerType
        self.offerSkip = offerSkip
        self.upperCtaText = upperCtaText
        self.discountRate = discountRate
        self.products = products
        self.notificationToggleState = notificationToggleState
    }

    init(withParams parameters: [String: Any], productCount: Int = 2) {
        if let value = parameters["onboardType"] as? String, !value.isEmpty,
           let type = OnboardingType(rawValue: value) {
            onboardType = type
        } else {
            onboardType = OnboardingType.default
        }
        
        if let value = parameters["designType"] as? String, !value.isEmpty,
           let type = PaywallType(rawValue: value) {
            designType = type
        } else {
            designType = PaywallType.defaultPaywall
        }
        
        upperCtaText = parameters["upper_cta_button"] as? String
        defaultProductIndex = ((parameters["defaultProduct"] as? Int) ?? .zero) - 1
        trialToggle = ((parameters["trial_toggle"] as? Int) ?? .zero)
        let notificationValue = parameters["notification_toggle"] as? Bool
        hasNotificationToggle = notificationValue != nil     // True when key exists
        notificationToggleState = notificationValue ?? false  // Key's value
        
        if let value = parameters["offerType"] as? String, !value.isEmpty,
           let type = OfferType(rawValue: value) {
            offerType = type
        } else {
            offerType = OfferType.noOffer
        }
        
        offerSkip = (parameters["offer_skip"] as? Bool) ?? false
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
