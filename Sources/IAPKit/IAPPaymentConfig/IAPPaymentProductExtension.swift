//
//  IAPPaymentProductExtension.swift
//
//
//  Created by Eser Kucuker on 5.05.2024.
//

import Foundation
import StoreKit

public extension IAPPaymentConfig.IAPPaymentProduct {

    static func == (lhs: IAPPaymentConfig.IAPPaymentProduct, rhs: IAPPaymentConfig.IAPPaymentProduct) -> Bool {
        lhs.productName == rhs.productName &&
        lhs.productPrice == rhs.productPrice &&
        lhs.productPriceDivide == rhs.productPriceDivide &&
        lhs.productTimeLabel == rhs.productTimeLabel &&
        lhs.productLocale == rhs.productLocale &&
        lhs.productLegalText == rhs.productLegalText &&
        lhs.productButtonTitle == rhs.productButtonTitle &&
        lhs.productTrailBadge == rhs.productTrailBadge
    }

    /// Returns the subtitle for a given product, considering its subscription price, localized time label, and default time value.
    /// - Parameters:
    ///   - skProduct: The `IAPProduct` representing the product
    ///   - placeholder: The default time value to be used if `productTimeLocalized` is not available..It must be localized string,
    ///   - productTimeLabelLocalized: The localized time label for the product. It must be localized string,
    /// - Returns:  A string representing the formatted subtitle for the product,
    /// including its price and time information.
    /// Returns `nil` if `productPriceDivide` is `nil` or less than or equal to zero.
    /// Example usage:
    /// ```
    /// let product = IAPProduct(...)
    /// let localizedSubtitle = subtitleForProduct(product, placeholder: "Month"localized(), productTimeLocalized: "Month")
    /// print(localizedSubtitle) // Output: "$4.99/Month"
    /// ```
    func subTitleForProduct(
        _ skProduct: IAPProduct?,
        placeholder: String,
        productTimeLabelLocalized: String?
    ) -> String? {
        let productPriceDivide = productPriceDivide
        let productTime = productTimeLabel
        let productPrice1 = skProduct?.subsciptionPrice.doubleValue ?? 0.0
        let productTimeLabel = productTime.isNilOrEmpty ? placeholder : productTimeLabelLocalized

        let currencySymbol = skProduct?.priceLocale.currencySymbol ?? ""
        let floatValue = Decimal(productPrice1)

        guard let productPriceDivide, productPriceDivide > 0 else { return nil }
        let divideDecimal = Decimal(productPriceDivide) // Ensure divide is also a Decimal
        let multiplied = floatValue / divideDecimal * Decimal(100)

        let truncatedValue = ((multiplied as NSDecimalNumber).rounding(accordingToBehavior: nil) as Decimal) / Decimal(100)

        let formattedPrice = String(format: "%.2f", NSDecimalNumber(decimal: truncatedValue).doubleValue)
            .replacingOccurrences(of: ".", with: ",")
            .replacingOccurrences(of: "\\,?0+$", with: "", options: .regularExpression)

        let timeString = (productTimeLabel != nil ? productTimeLabel : placeholder) ?? ""

        return "\(currencySymbol)\(formattedPrice)" + "/" + timeString
    }

    /// Returns the name for a given product You should use the returned string with the localized function. You should use the returned string with the localized function.
    /// - Parameters:
    ///   - skProduct: The `IAPProduct` representing the product
    ///   - defaultlocalizedDateText: The default localized date text to be used if `productName` is not available.  It must be localized string,
    /// - Returns:  A string representing the name of the product. If `productName` is nil or empty, returns `defaultlocalizedDateText`.
    /// Example usage:
    /// ```
    /// let product = IAPProduct(...)
    /// var config: IAPPaymentConfig.IAPPaymentProduct?
    /// let productName = "productTitle:\(product.identifier)".localized
    /// let localizedSubtitle = config?.name(forSKProduct: product, defaultlocalizedDateText: productName)?.localized
    /// print(localizedSubtitle) // Output: ""3 Days Free""
    /// ```
    func name(placeholder: String?) -> String? {
        productName.isNilOrEmpty ? placeholder : productName
    }

    /// Returns the price title for a given product and product locale.
    /// - Parameters:
    ///   - skProduct: The `IAPProduct` representing the product
    ///   - productLocale: The locale of the product.  It must be localized string,
    /// - Returns:A string representing the formatted price title of the product including its price and locale.
    /// Example usage:
    /// ```
    /// let product = IAPProduct(...)
    /// var config: IAPPaymentConfig.IAPPaymentProduct?
    /// let defaultUnitName = (config?.productLocale == nil ) ? product.subscriptionPeriodText.localized : (config?.productLocale?.localized ?? "")
    /// let productPrice = config?.priceTitle(skProduct: product, productLocale: defaultUnitName)
    /// print(productPrice) // Output: "$4.99/USD" (if available) or "0.99/USD" (if not available)
    /// ```
    func priceTitle(skProduct: IAPProduct?, productLocale: String) -> String {

        let price2 = productPrice
        let divide = price2.isNil || price2 ?? 0 > 0 ? (price2 ?? 0) : 1.0

        var customPrice = Decimal(skProduct?.subsciptionPrice.doubleValue ?? 0.0)
        
        let divideDecimal = Decimal(divide) // Ensure divide is also a Decimal
        let multiplied = customPrice / divideDecimal * Decimal(100)

        customPrice = ((multiplied as NSDecimalNumber).rounding(accordingToBehavior: nil) as Decimal) / Decimal(100)
        
        let doubleCustomPrice = NSDecimalNumber(decimal: customPrice).doubleValue
        
        let formattedPrice = formattedCustomPrice(doubleCustomPrice, alternativePrice: skProduct?.priceString() ?? "")

        let skCurrency = skProduct?.priceLocale.currencySymbol ?? ""
        let price = (customPrice > 0) ? skCurrency + formattedPrice : formattedPrice
        return price + "/" + productLocale
    }

    func formattedCustomPrice(_ customPrice: Double, alternativePrice: String) -> String {
        (customPrice > 0) ? formatedCustomPrice(customPrice) : alternativePrice
    }

    func formatedCustomPrice(_ customPrice: Double) -> String {
        if customPrice.truncatingRemainder(dividingBy: 1.0) == .zero {
            String(format: "%.0f", customPrice).replacingOccurrences(of: ".", with: ",")
        } else {
            String(format: "%.2f", customPrice).replacingOccurrences(of: ".", with: ",")
        }
    }

    /// Returns the button title for a given product. You should use the returned string with the localized function
    /// - Parameters:
    ///   - skProduct: The `IAPProduct` representing the product
    ///   - defaultButtonTitle: The default button title to be used if `productButtonTitle` is not available.  It must be localized string,
    /// - Returns: A string representing the button title of the product. Returns `defaultButtonTitle` if `productButtonTitle` is nil or empty.
    /// You should use the returned string with the localized function
    /// Example usage:
    /// ```
    /// var config: IAPPaymentConfig.IAPPaymentProduct?
    /// let defaultButtonTitle = "Subscribe"
    /// let buttonTitle = buttonTitle(defaultButtonTitle: defaultButtonTitle)
    /// print(buttonTitle) // Output: "Subscribe" (if available) or "Become Premium" (if not available)
    /// ```
    func buttonTitle(defaultButtonTitle: String) -> String? {
        productButtonTitle.isNilOrEmpty ? defaultButtonTitle : productButtonTitle
    }
}
