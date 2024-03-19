//
//  IAPMonthlyProduct.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Foundation

class MonthlyProduct: IAPProduct {
    static let productIdentifier = "com.madduck.callrecorder.default3Month2"

    override var identifier: String { Self.productIdentifier }
    override func hasFreeTrial() -> Bool { false }
    override func isWeekly() -> Bool { false }
    override func isMonthly() -> Bool { false }
    override func is2Monthly() -> Bool { false }
    override func is3Monthly() -> Bool { true }
    override func is6Monthly() -> Bool { false }
    override func isYearly() -> Bool { false }
    override var subscriptionPeriodText: String {
        let dateComponents = DateComponents(month: 3)
        return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(
            of: "1 ", with: ""
        ) ?? ""
    }

    override func weeklyPrice() -> Double? { nil }
    override var priceLocale: Locale { Locale.current }
    override var units: Int? { nil }
    override var subsciptionPrice: NSDecimalNumber { 1199.99 }
}
