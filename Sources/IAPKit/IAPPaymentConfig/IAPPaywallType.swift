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
        case timelineToggle
        case buttons = "Buttons"
        case singleProductPlan = "Single-Plan"
        case singleProductPlanSecondDesign = "singlePlan"
        case singleProductPlanWithToggle = "singlePlan_toggle"
        case plan2Toggle = "2planToggle"
        case rink2PTimelineSingle = "rink2pTimelineSingle"
        case rink2PTimelineVertical = "rink2pTimelineVR"
        case rink2PTimelineHorizontal = "rink2pTimelineHR"
    }

    enum IAPOnboardingType: String {
        case single
        case multiple
        case `default`
    }

    enum IAPOfferType: String {
        case noOffer
        // CallRecorder types
        case yearOffer = "year_offer"
        // interviewRecorder types
        case offerVariantA = "offerVarA"
        case offerVariantB = "offerVarB"
    }
}
