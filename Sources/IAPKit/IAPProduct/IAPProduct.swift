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
    public var product: IAPProductProtocol!
    // swiftlint:enable implicitly_unwrapped_optional

    init() {
        // empty initializer
    }

    public init(product: IAPProductProtocol) {
        self.product = product
    }

    /// Creates a minimal product with only an identifier (used for live paywall callbacks)
    public convenience init(identifier: String) {
        self.init()
        self.product = PlaceholderProduct(identifier: identifier)
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
    public var introductoryPricePaymentMode: UInt { product.introductoryPricePaymentMode }
    public var periodUnit: IAPPeriodUnit.PeriodUnit { product.periodUnit }
    public var localizedPrice: String { product.localizedPrice }
}

extension IAPProduct: Equatable {
    public static func == (lhs: IAPProduct, rhs: IAPProduct) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

public protocol IAPProductProtocol {
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
    var introductoryPricePaymentMode: UInt { get }
    var periodUnit: IAPPeriodUnit.PeriodUnit { get }
    var localizedPrice: String { get }
}

@available(iOS 15.0, *) extension Product: IAPProductProtocol {
    public var identifier: String { id }

    public func hasFreeTrial() -> Bool {
        subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    public func isWeekly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 7 && subscription?.subscriptionPeriod.unit == .day) ||
            (subscription?.subscriptionPeriod.value ?? 0 == 1 && subscription?.subscriptionPeriod.unit == .week)
    }

    public func isMonthly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 1 && subscription?.subscriptionPeriod.unit == .month)
    }

    public func is2Monthly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 2 && subscription?.subscriptionPeriod.unit == .month)
    }

    public func is3Monthly() -> Bool {
        (subscription?.subscriptionPeriod.value == 3 && subscription?.subscriptionPeriod.unit == .month)
    }

    public func is6Monthly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 6 && subscription?.subscriptionPeriod.unit == .month)
    }

    public func isYearly() -> Bool {
        (subscription?.subscriptionPeriod.value ?? 0 == 12 && subscription?.subscriptionPeriod.unit == .month) ||
            (subscription?.subscriptionPeriod.value ?? 0 == 1 && subscription?.subscriptionPeriod.unit == .year)
    }

    public var subscriptionPeriodText: String {
        guard let subscriptionPeriod = subscription?.subscriptionPeriod else { return "" }
        let dateComponents = switch subscriptionPeriod.unit {
        case .day:
            if subscriptionPeriod.value == 7 {
                DateComponents(weekOfMonth: 1)
            } else {
                DateComponents(day: subscriptionPeriod.value)
            }
        case .week: DateComponents(weekOfMonth: subscriptionPeriod.value)
        case .month: DateComponents(month: subscriptionPeriod.value)
        case .year: DateComponents(year: subscriptionPeriod.value)
        @unknown default:
            DateComponents(month: subscriptionPeriod.value)
        }
        return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(
            of: "1 ",
            with: ""
        ) ?? ""
    }

    public func weeklyPrice() -> Double? {
        if let period = subscription?.subscriptionPeriod, period.unit != .week || period.value > 1,
           period.unit != .day
        {
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

    public var priceLocale: Locale {
        priceFormatStyle.locale
    }

    public var units: Int? {
        subscription?.subscriptionPeriod.value
    }

    public var subsciptionPrice: NSDecimalNumber {
        price as NSDecimalNumber
    }

    public func subscriptionPeriodUnit(withWeekly weekly: String, monthly: String, yearly: String) -> String {
        guard let unit = subscription?.subscriptionPeriod.unit else { return "" }

        switch unit {
        case .day: return ((subscription?.subscriptionPeriod.value ?? .zero) > 1) ? weekly : "daily"
        case .week: return weekly
        case .month: return monthly
        case .year: return yearly
        @unknown default: return ""
        }
    }

    public var subscriptionPeriodUnitRawValue: UInt {
        switch subscription?.subscriptionPeriod.unit {
        case .week: 1
        case .month: 2
        case .year: 3
        default: .zero
        }
    }

    public var introductoryPricePaymentMode: UInt {
        var paymentMode: UInt = 0
        if subscription?.introductoryOffer?.paymentMode == .payAsYouGo {
            paymentMode = 0
        } else if subscription?.introductoryOffer?.paymentMode == .payUpFront {
            paymentMode = 1
        } else if subscription?.introductoryOffer?.paymentMode == .freeTrial {
            paymentMode = 2
        }
        return paymentMode
    }

    public var periodUnit: IAPPeriodUnit.PeriodUnit {
        switch subscription?.subscriptionPeriod.unit {
        case .day: ((subscription?.subscriptionPeriod.value ?? .zero) > 1) ? .week : .day
        case .week: .week
        case .month: .month
        case .year: .year
        default: .day
        }
    }

    public var localizedPrice: String {
        displayPrice
    }
}

extension SKProduct: IAPProductProtocol {
    public var identifier: String { productIdentifier }

    public func hasFreeTrial() -> Bool {
        introductoryPrice?.subscriptionPeriod.numberOfUnits ?? 0 > 0
    }

    public func isWeekly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 7 && subscriptionPeriod?.unit == .day) ||
            (subscriptionPeriod?.numberOfUnits ?? 0 == 1 && subscriptionPeriod?.unit == .week)
    }

    public func isMonthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 1 && subscriptionPeriod?.unit == .month)
    }

    public func is2Monthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 2 && subscriptionPeriod?.unit == .month)
    }

    public func is3Monthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 3 && subscriptionPeriod?.unit == .month)
    }

    public func is6Monthly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 6 && subscriptionPeriod?.unit == .month)
    }

    public func isYearly() -> Bool {
        (subscriptionPeriod?.numberOfUnits ?? 0 == 12 && subscriptionPeriod?.unit == .month) ||
            (subscriptionPeriod?.numberOfUnits ?? 0 == 1 && subscriptionPeriod?.unit == .year)
    }

    public var subscriptionPeriodText: String {
        guard let subscriptionPeriod else { return "" }
        let dateComponents = switch subscriptionPeriod.unit {
        case .day:
            if subscriptionPeriod.numberOfUnits == 7 {
                DateComponents(weekOfMonth: 1)
            } else {
                DateComponents(day: subscriptionPeriod.numberOfUnits)
            }
        case .week: DateComponents(weekOfMonth: subscriptionPeriod.numberOfUnits)
        case .month: DateComponents(month: subscriptionPeriod.numberOfUnits)
        case .year: DateComponents(year: subscriptionPeriod.numberOfUnits)
        @unknown default:
            DateComponents(month: subscriptionPeriod.numberOfUnits)
        }
        return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(
            of: "1 ",
            with: ""
        ) ?? ""
    }

    public func weeklyPrice() -> Double? {
        if let period = subscriptionPeriod, period.unit != .week || period.numberOfUnits > 1,
           period.unit != .day
        {
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

    public var units: Int? {
        introductoryPrice?.subscriptionPeriod.numberOfUnits
    }

    public var subsciptionPrice: NSDecimalNumber {
        price
    }

    public func subscriptionPeriodUnit(withWeekly weekly: String, monthly: String, yearly: String) -> String {
        guard let unit = subscriptionPeriod?.unit else { return "" }

        switch unit {
        case .day: return ((subscriptionPeriod?.numberOfUnits ?? .zero) > 1) ? weekly : "daily"
        case .week: return weekly
        case .month: return monthly
        case .year: return yearly
        @unknown default: return ""
        }
    }

    public var subscriptionPeriodUnitRawValue: UInt {
        subscriptionPeriod?.unit.rawValue ?? .zero
    }

    public var introductoryPricePaymentMode: UInt {
        introductoryPrice?.paymentMode.rawValue ?? .zero
    }

    public var periodUnit: IAPPeriodUnit.PeriodUnit {
        switch subscriptionPeriod?.unit {
        case .day: ((subscriptionPeriod?.numberOfUnits ?? .zero) > 1) ? .week : .day
        case .week: .week
        case .month: .month
        case .year: .year
        default: .day
        }
    }

    public var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? ""
    }
}

// MARK: - Placeholder Product

/// A minimal product implementation used when only the identifier is known
struct PlaceholderProduct: IAPProductProtocol {
    let identifier: String

    func hasFreeTrial() -> Bool { false }
    func isWeekly() -> Bool { false }
    func isMonthly() -> Bool { false }
    func is2Monthly() -> Bool { false }
    func is3Monthly() -> Bool { false }
    func is6Monthly() -> Bool { false }
    func isYearly() -> Bool { false }
    var subscriptionPeriodText: String { "" }
    func weeklyPrice() -> Double? { nil }
    var priceLocale: Locale { .current }
    var units: Int? { nil }
    var subsciptionPrice: NSDecimalNumber { 0 }
    func subscriptionPeriodUnit(withWeekly weekly: String, monthly: String, yearly: String) -> String { "" }
    var subscriptionPeriodUnitRawValue: UInt { 0 }
    var introductoryPricePaymentMode: UInt { 0 }
    var periodUnit: IAPPeriodUnit.PeriodUnit { .day }
    var localizedPrice: String { "" }
}
