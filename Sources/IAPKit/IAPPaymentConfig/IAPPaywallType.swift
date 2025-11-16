//
//  IAPPaywallType.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation

public extension IAPPaymentConfig {
    protocol IAPPaywallType: RawRepresentable, Equatable, Hashable where RawValue == String {
        static var defaultValue: Self { get }
    }
    
    protocol IAPOnboardingType: RawRepresentable, Equatable, Hashable where RawValue == String {
        static var defaultValue: Self { get }
    }
    
    protocol IAPOfferType: RawRepresentable, Equatable, Hashable where RawValue == String {
        static var defaultValue: Self { get }
    }
}

public enum DefaultPaywallType: String, IAPPaymentConfig.IAPPaywallType {
    case defaultPaywall
    public static var defaultValue: Self { .defaultPaywall }
}

public enum DefaultOnboardingType: String, IAPPaymentConfig.IAPOnboardingType {
    case `default`
    public static var defaultValue: Self { .default }
}

public enum DefaultOfferType: String, IAPPaymentConfig.IAPOfferType {
    case noOffer
    public static var defaultValue: Self { .noOffer }
}

public struct IAPConfigTypeMapper {
    public static var paywallType: (any IAPPaymentConfig.IAPPaywallType.Type) = DefaultPaywallType.self
    public static var onboardingType: (any IAPPaymentConfig.IAPOnboardingType.Type) = DefaultOnboardingType.self
    public static var offerType: (any IAPPaymentConfig.IAPOfferType.Type) = DefaultOfferType.self
}
