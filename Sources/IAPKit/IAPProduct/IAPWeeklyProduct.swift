//
//  IAPWeeklyProduct.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Foundation

class WeeklyProduct: IAPProduct {
    static let productIdentifier = "com.madduck.callrecorder.default1Week2"

    override var identifier: String { Self.productIdentifier }
    override func hasFreeTrial() -> Bool { true }
    override func isWeekly() -> Bool { true }
    override func isMonthly() -> Bool { false }
    override func is2Monthly() -> Bool { false }
    override func is3Monthly() -> Bool { false }
    override func is6Monthly() -> Bool { false }
    override func isYearly() -> Bool { false }
    override var subscriptionPeriodText: String {
        let dateComponents = DateComponents(weekOfMonth: 1)
        return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(
            of: "1 ", with: ""
        ) ?? ""
    }

    override func weeklyPrice() -> Double? { nil }
    override var priceLocale: Locale { Locale.current }
    override var units: Int? { 3 }
    override var subsciptionPrice: NSDecimalNumber { 249.99 }
}
