//
//  RegisterRequest.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

public struct RegisterRequest: Encodable {
    public let userId: String?
    public let sdkKey: String?

    public init(
        userId: String?,
        sdkKey: String?,
    ) {
        self.userId = userId
        self.sdkKey = sdkKey
    }
}
