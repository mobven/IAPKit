//
//  SignInRequest.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation

public struct SignInRequest: Encodable {
    public let identityToken: Data?
    public let nameSurname: String?
    public let deviceId: String?
    public let deviceName: String?
    public let platform: String?
    public let pushNotificationEnabled: Bool?
    public let pushNotificationToken: String?

    public init(
        identityToken: Data?,
        nameSurname: String?,
        deviceId: String?,
        deviceName: String?,
        platform: String?,
        pushNotificationEnabled: Bool? = false,
        pushNotificationToken: String? = ""
    ) {
        self.identityToken = identityToken
        self.nameSurname = nameSurname
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.platform = platform
        self.pushNotificationEnabled = pushNotificationEnabled
        self.pushNotificationToken = pushNotificationToken
    }
}
