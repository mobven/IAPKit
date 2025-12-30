//
//  User+Properties.swift
//  User
//
//  Created by Eser Kucuker on 5.06.2025.
//

import Foundation

// MARK: - User Properties

public extension User {
    var id: String? {
        get { info?.id }
        set { info?.id = newValue }
    }

    var fullName: String? {
        get { info?.fullName }
        set { info?.fullName = newValue ?? "" }
    }

    var email: String? {
        get { info?.email }
        set { info?.email = newValue }
    }

    var isRegistered: Bool {
        get { info?.isRegistered ?? false }
        set { info?.isRegistered = newValue }
    }

    var pushNotificationEnabled: Bool {
        get { info?.pushNotificationEnabled ?? false }
        set { info?.pushNotificationEnabled = newValue }
    }

    var pushNotificationToken: String? {
        get { info?.pushNotificationToken }
        set { info?.pushNotificationToken = newValue ?? "" }
    }
}
