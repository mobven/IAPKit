//
//  IAPPaywallType.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation

public extension IAPPaymentConfig {
    enum IAPPaywallType: String {
        case defaultPaywall
        case eft
        case offer
        case plan2Vertical = "2plan_vertical"
        case plan2Horizontal = "2plan_horizontal"
        case plan3Vertical = "3plan_vertical"
        case plan3Horizontal = "3plan_horizontal"
        case timeLine = "Timeline"
    }

    enum IAPOnboardingType: String {
        case single
        case multiple
    }
}
