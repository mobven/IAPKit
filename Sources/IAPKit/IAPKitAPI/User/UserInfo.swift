//
//  UserInfo.swift
//  User
//
//  Created by Eser Kucuker on 5.06.2025.
//

import Foundation
import UIKit

// MARK: - UserCodable

public protocol UserCodable: Codable {
    var id: String? { get set }
    var fullName: String { get set }
    var email: String? { get set }
    var isRegistered: Bool { get set }
    var kid: User.Kid? { get set }
    var pushNotificationEnabled: Bool { get set }
    var pushNotificationToken: String { get set }
}

public extension User {
    struct Info: UserCodable, Equatable {
        public var id: String?
        public var fullName: String
        public var email: String?
        public var isRegistered: Bool
        public var kid: User.Kid?
        public var pushNotificationEnabled: Bool
        public var pushNotificationToken: String

        public init(
            id: String? = nil,
            fullName: String = "",
            isRegistered: Bool = false,
            kid: User.Kid? = nil,
            pushNotificationEnabled: Bool = false,
            pushNotificationToken: String = ""
        ) {
            self.id = id
            self.fullName = fullName
            self.isRegistered = isRegistered
            self.kid = kid
            self.pushNotificationEnabled = pushNotificationEnabled
            self.pushNotificationToken = pushNotificationToken
        }
    }
}

public extension User {
    struct Kid: Codable, Equatable, Sendable {
        public let id: String?
        public let name: String?
        public let birthDate: Date?
        public let gender: String?
        public let photoURL: String?

        public init(id: String?, name: String?, birthDate: Date?, gender: String?, photoURL: String?) {
            self.id = id
            self.name = name
            self.birthDate = birthDate
            self.gender = gender
            self.photoURL = photoURL
        }
    }
}

public extension User.Kid {
    var profileImageURL: String? {
        guard let photoURLString = photoURL else { return nil }
        return Bundle.main.infoForKey("BASE_URL")?.appending(photoURLString)
    }
}
