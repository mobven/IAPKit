//
//  IAPAttributionData.swift
//  IAPKit
//
//  Created by IAPKit on 08.01.2026.
//

import Foundation

/// Attribution data for marketing campaign tracking
/// Used to send campaign/ad attribution data to IAP providers (RevenueCat, Adapty)
public struct IAPAttributionData {

    /// The creative name/ID (e.g., ad image or text identifier)
    public var creative: String?

    /// The campaign name (e.g., "Summer_Sale_2024")
    public var campaign: String?

    /// The ad group/set name
    public var adGroup: String?

    /// The media source/network (e.g., "Facebook", "Google", "Organic")
    public var mediaSource: String?

    /// Custom key-value attributes to send to the provider
    public var customAttributes: [String: String]?

    public init(
        creative: String? = nil,
        campaign: String? = nil,
        adGroup: String? = nil,
        mediaSource: String? = nil,
        customAttributes: [String: String]? = nil
    ) {
        self.creative = creative
        self.campaign = campaign
        self.adGroup = adGroup
        self.mediaSource = mediaSource
        self.customAttributes = customAttributes
    }
}
