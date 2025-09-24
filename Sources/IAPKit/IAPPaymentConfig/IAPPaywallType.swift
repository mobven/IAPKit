//
//  IAPPaywallType.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation

public extension IAPPaymentConfig {
    enum IAPPaywallType: String {
        case eft
        case offer
        case plan2Vertical = "2plan_vertical"
        case plan2Horizontal = "2plan_horizontal"
        case plan3Vertical = "3plan_vertical"
        case plan3Horizontal = "3plan_horizontal"
        case buttons = "Buttons"
        case plan2Toggle = "2planToggle"
        case rink2PTimelineSingle = "rink2pTimelineSingle"
        case rink2PTimelineVertical = "rink2pTimelineVR"
        case rink2PTimelineHorizontal = "rink2pTimelineHR"
        case rink2PTimelineVRToggle = "rink2pTimelineVR-toggle"
        case buttonsVR = "buttonsVR"
        case reminderTimeline = "reminder_timeline"
        // Flick Paywalls
        case defaultPaywall
        case timeLine = "Timeline"
        case timelineToggle
        case singleProductPlan = "Single-Plan"
        case singleProductPlanSecondDesign = "singlePlan"
        case singleProductPlanWithToggle = "singlePlan_toggle"
        case business = "Business"
        case personal = "Personal"
        case featurePaywall
        case notebook
    }

    enum IAPOnboardingType: String {
        case `default`
        // Call Recorder onboard types
        case single
        case multiple
        case personalGreen
        case personalRed
        case socialProofV2 = "socialproofv2"
        // Flick onboard types
        case personal
        case notebook
        case question
    }

    enum IAPOfferType: String {
        case noOffer
        // CallRecorder types
        case yearOffer = "year_offer"
        case singleYearOffer = "single_yearOffer"
        // interviewRecorder types
        case offerVariantA = "offerVarA"
        case offerVariantB = "offerVarB"
        case popupOffer = "popup_offer" // native alert gibi gözüken offer
    }
}
