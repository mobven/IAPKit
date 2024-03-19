//
//  IAPSubscription.swift
//  IAPKit
//
//  Created by Rashid Ramazanov on 19.03.2024.
//

import Foundation

public struct IAPSubscription {
    public let vendorTransactionId: String
    public let activatedAt: Date
    public let isInGracePeriod: Bool
    public let activeIntroductoryOfferType: String?
    public let vendorProductId: String
}
