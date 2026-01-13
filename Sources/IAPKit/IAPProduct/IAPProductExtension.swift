//
//  IAPProductExtension.swift
//  Rink
//
//  Created by Anil Oruc on 29.05.2023.
//

import StoreKit

public extension IAPProduct {
    func priceString() -> String? {
        if subsciptionPrice == 0 {
            return "Free!" // or whatever you like
        } else {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = priceLocale
            return numberFormatter.string(from: subsciptionPrice)
        }
    }

    func currency() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = priceLocale
        return numberFormatter.currencyCode
    }

    func unitName(weekly: String, monthly: String, yearly: String) -> String {
        let weekly = NSLocalizedString(weekly, comment: "")
        let monthly = NSLocalizedString(monthly, comment: "")
        let yearly = NSLocalizedString(yearly, comment: "")
        return subscriptionPeriodUnit(withWeekly: weekly, monthly: monthly, yearly: yearly)
    }

    func localizedDateText(weekly: String, monthly: String, yearly: String) -> String {
        if isWeekly() { return weekly }
        switch subscriptionPeriodUnitRawValue {
        case 1: // Weekly
            return weekly
        case 2: // Monthly
            return monthly
        case 3: // Yearly
            return yearly
        default:
            return ""
        }
    }
}
