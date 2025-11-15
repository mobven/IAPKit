//
//  IAPPaywallType.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation

public extension IAPPaymentConfig {
    protocol IAPPaywallType: RawRepresentable, Equatable, Hashable where RawValue == String {}
    
    protocol IAPOnboardingType: RawRepresentable, Equatable, Hashable where RawValue == String {}
    
    protocol IAPOfferType: RawRepresentable, Equatable, Hashable where RawValue == String {}
}

// Default implementation types
public enum PaywallType: String, IAPPaymentConfig.IAPPaywallType {
    case defaultPaywall
}

public enum OnboardingType: String, IAPPaymentConfig.IAPOnboardingType {
    case `default`
}

public enum OfferType: String, IAPPaymentConfig.IAPOfferType {
    case noOffer
}
