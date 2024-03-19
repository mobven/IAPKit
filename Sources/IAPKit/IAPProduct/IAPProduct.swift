//
//  IAPProduct.swift
//  Rink
//
//  Created by Rashid Ramazanov on 23.01.2024.
//

import Foundation
import StoreKit

public class IAPProduct: IAPProductProtocol {
    // swiftlint:disable implicitly_unwrapped_optional
    var product: IAPProductProtocol!
    // swiftlint:enable implicitly_unwrapped_optional

    init() {
        // empty initializer
    }

    init(product: IAPProductProtocol) {
        self.product = product
    }

    public var identifier: String { product.identifier }
    public func hasFreeTrial() -> Bool { product.hasFreeTrial() }
    public func isWeekly() -> Bool { product.isWeekly() }
    public func isMonthly() -> Bool { product.isMonthly() }
    public func is2Monthly() -> Bool { product.is2Monthly() }
    public func is3Monthly() -> Bool { product.is3Monthly() }
    public func is6Monthly() -> Bool { product.is6Monthly() }
    public func isYearly() -> Bool { product.isYearly() }
    public var subscriptionPeriodText: String { product.subscriptionPeriodText }
    public func weeklyPrice() -> Double? { product.weeklyPrice() }
    public var priceLocale: Locale { product.priceLocale }
    public var units: Int? { product.units }
    public var subsciptionPrice: NSDecimalNumber { product.subsciptionPrice }
    public func subscriptionPeriodUnit(withWeekly weekly: String, monthly: String, yearly: String) -> String {
        product.subscriptionPeriodUnit(withWeekly: weekly, monthly: monthly, yearly: yearly)
    }
    public var subscriptionPeriodUnitRawValue: UInt { product.subscriptionPeriodUnitRawValue }
}

extension IAPProduct: Equatable {
    public static func == (lhs: IAPProduct, rhs: IAPProduct) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

protocol IAPProductProtocol {
    var identifier: String { get }
    func hasFreeTrial() -> Bool
    func isWeekly() -> Bool
    func isMonthly() -> Bool
    func is2Monthly() -> Bool
    func is3Monthly() -> Bool
    func is6Monthly() -> Bool
    func isYearly() -> Bool
    var subscriptionPeriodText: String { get }
    func weeklyPrice() -> Double?
    var priceLocale: Locale { get }
    var units: Int? { get }
    var subsciptionPrice: NSDecimalNumber { get }
    func subscriptionPeriodUnit(withWeekly weekly: String, monthly: String, yearly: String) -> String
    var subscriptionPeriodUnitRawValue: UInt { get }
}

@available(iOS 15.0, *) extension Product: IAPProductProtocol {
    var identifier: String { id }

    func hasFreeTrial() -> Bool {
        subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    func isWeekly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 7 && subscription?.subscriptionPeriod.unit == .day) ||
            (subscription?.subscriptionPeriod.value ?? 0 == 1 && subscription?.subscriptionPeriod.unit == .week)
    }

    func isMonthly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 1 && subscription?.subscriptionPeriod.unit == .month)
    }

    func is2Monthly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 2 && subscription?.subscriptionPeriod.unit == .month)
    }

    func is3Monthly() -> Bool {
        (subscription?.subscriptionPeriod.value == 3 && subscription?.subscriptionPeriod.unit == .month)
    }

    func is6Monthly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 6 && subscription?.subscriptionPeriod.unit == .month)
    }

    func isYearly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 12 && subscription?.subscriptionPeriod.unit == .month) ||
            (subscription?.subscriptionPeriod.value ?? 0 == 1 && subscription?.subscriptionPeriod.unit == .year)
    }

    var subscriptionPeriodText: String {
        guard let subscriptionPeriod = subscription?.subscriptionPeriod else { return "" }
        let dateComponents: DateComponents
        switch subscriptionPeriod.unit {
        case .day:
            if subscriptionPeriod.value == 7 {
                dateComponents = DateComponents(weekOfMonth: 1)
            } else {
                dateComponents = DateComponents(day: subscriptionPeriod.value)
            }
        case .week: dateComponents = DateComponents(weekOfMonth: subscriptionPeriod.value)
        case .month: dateComponents = DateComponents(month: subscriptionPeriod.value)
        case .year: dateComponents = DateComponents(year: subscriptionPeriod.value)
        @unknown default:
            dateComponents = DateComponents(month: subscriptionPeriod.value)
        }
        return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(
            of: "1 ",
            with: ""
        ) ?? ""
    }

    func weeklyPrice() -> Double? {
        if let period = subscription?.subscriptionPeriod, period.unit != .week || period.value > 1,
           period.unit != .day {
            var priceDoubleForWeek: Double?
            switch period.unit {
            case .day:
                break
            case .week:
                priceDoubleForWeek = (Double(truncating: price as NSNumber) / Double(period.value))
            case .month:
                priceDoubleForWeek = (Double(truncating: price as NSNumber) / Double(period.value * 30) * 7)
            case .year:
                priceDoubleForWeek = (Double(truncating: price as NSNumber) / Double(period.value * 365) * 7)
            @unknown default:
                break
            }
            return priceDoubleForWeek
        }
        return nil
    }

    var priceLocale: Locale {
        priceFormatStyle.locale
    }

    var units: Int? {
        subscription?.subscriptionPeriod.value
    }

    var subsciptionPrice: NSDecimalNumber {
        price as NSDecimalNumber
    }

    func subscriptionPeriodUnit(withWeekly weekly: String, monthly: String, yearly: String) -> String {
        guard let unit = subscription?.subscriptionPeriod.unit else { return "" }

        switch unit {
        case .day: return ((subscription?.subscriptionPeriod.value ?? .zero) > 1) ? weekly : "daily"
        case .week: return weekly
        case .month: return monthly
        case .year: return yearly
        @unknown default: return ""
        }
    }

    var subscriptionPeriodUnitRawValue: UInt {
        return switch subscription?.subscriptionPeriod.unit {
        case .week: 1
        case .month: 2
        case .year: 3
        default: .zero
        }
    }
}

extension SKProduct: IAPProductProtocol {
    var identifier: String { productIdentifier }

    func hasFreeTrial() -> Bool {
        introductoryPrice?.subscriptionPeriod.numberOfUnits ?? 0 > 0
    }

    func isWeekly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 7 && subscriptionPeriod?.unit == .day) ||
            (subscriptionPeriod?.numberOfUnits ?? 0 == 1 && subscriptionPeriod?.unit == .week)
    }

    func isMonthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 1 && subscriptionPeriod?.unit == .month)
    }

    func is2Monthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 2 && subscriptionPeriod?.unit == .month)
    }

    func is3Monthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 3 && subscriptionPeriod?.unit == .month)
    }

    func is6Monthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 6 && subscriptionPeriod?.unit == .month)
    }

    func isYearly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 12 && subscriptionPeriod?.unit == .month) ||
            (subscriptionPeriod?.numberOfUnits ?? 0 == 1 && subscriptionPeriod?.unit == .year)
    }

    var subscriptionPeriodText: String {
        guard let subscriptionPeriod else { return "" }
        let dateComponents: DateComponents
        switch subscriptionPeriod.unit {
        case .day:
            if subscriptionPeriod.numberOfUnits == 7 {
                dateComponents = DateComponents(weekOfMonth: 1)
            } else {
                dateComponents = DateComponents(day: subscriptionPeriod.numberOfUnits)
            }
        case .week: dateComponents = DateComponents(weekOfMonth: subscriptionPeriod.numberOfUnits)
        case .month: dateComponents = DateComponents(month: subscriptionPeriod.numberOfUnits)
        case .year: dateComponents = DateComponents(year: subscriptionPeriod.numberOfUnits)
        @unknown default:
            dateComponents = DateComponents(month: subscriptionPeriod.numberOfUnits)
        }
        return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(
            of: "1 ",
            with: ""
        ) ?? ""
    }

    func weeklyPrice() -> Double? {
        if let period = subscriptionPeriod, period.unit != .week || period.numberOfUnits > 1,
           period.unit != .day {
            var priceDoubleForWeek: Double?
            switch period.unit {
            case .day:
                break
            case .week:
                priceDoubleForWeek = (price.doubleValue / Double(period.numberOfUnits))
            case .month:
                priceDoubleForWeek = (price.doubleValue / Double(period.numberOfUnits * 30) * 7)
            case .year:
                priceDoubleForWeek = (price.doubleValue / Double(period.numberOfUnits * 365) * 7)
            @unknown default:
                break
            }
            return priceDoubleForWeek
        }
        return nil
    }

    var locale: Locale { priceLocale }

    var units: Int? {
        introductoryPrice?.subscriptionPeriod.numberOfUnits
    }

    var subsciptionPrice: NSDecimalNumber {
        price
    }

    func subscriptionPeriodUnit(withWeekly weekly: String, monthly: String, yearly: String) -> String {
        guard let unit = subscriptionPeriod?.unit else { return "" }

        switch unit {
        case .day: return ((subscriptionPeriod?.numberOfUnits ?? .zero) > 1) ? weekly : "daily"
        case .week: return weekly
        case .month: return monthly
        case .year: return yearly
        @unknown default: return ""
        }
    }

    var subscriptionPeriodUnitRawValue: UInt {
        subscriptionPeriod?.unit.rawValue ?? .zero
    }
}
