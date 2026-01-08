//
//  ReceiptValidationRequest.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 5.01.2026.
//

import Foundation

/// Request body for IAP buy and restore endpoints
/// Used for both `/api/v1/iap/buy` and `/api/v1/iap/restore`
public struct ReceiptValidationRequest: Encodable, Sendable {
    /// Base64 encoded App Store receipt string
    public let receiptData: String

    public init(receiptData: String) {
        self.receiptData = receiptData
    }
}
