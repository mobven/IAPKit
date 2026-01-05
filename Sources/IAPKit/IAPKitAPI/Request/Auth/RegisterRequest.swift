//
//  RegisterRequest.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

public struct RegisterRequest: Encodable {
    public let userId: String?
    public let appId: String?

    public init(
        userId: String?,
        appId: String?,
    ) {
        self.userId = userId
        self.appId = appId
    }
}
