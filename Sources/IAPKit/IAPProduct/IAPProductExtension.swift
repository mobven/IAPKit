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
}
