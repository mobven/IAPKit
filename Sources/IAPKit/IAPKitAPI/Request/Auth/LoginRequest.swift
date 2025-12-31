//
//  LoginRequest.swift
//  IAPKit
//
//  Created by Cansu Özdizlekli on 31.12.2025.
//

import Foundation

public struct LoginRequest: Encodable {
    public let identityToken: Data?
    public let nameSurname: String?
    public let deviceId: String?
    public let deviceName: String?
    public let platform: String?

    public init(
        identityToken: Data?,
        nameSurname: String?,
        deviceId: String?,
        deviceName: String?,
        platform: String?,
    ) {
        self.identityToken = identityToken
        self.nameSurname = nameSurname
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.platform = platform
    }
}
