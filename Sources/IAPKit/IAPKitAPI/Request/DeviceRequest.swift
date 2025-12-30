//
//  DeviceRequest.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation

public struct DeviceRequest {
    let id: String
    let name: String
    let platform: String
    let pushNotificationToken: String

    public init(
        id: String,
        name: String,
        platform: String,
        pushNotificationToken: String
    ) {
        self.id = id
        self.name = name
        self.platform = platform
        self.pushNotificationToken = pushNotificationToken
    }
}
