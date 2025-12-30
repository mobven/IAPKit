//
//  GetUserResponse.swift
//  API
//
//  Created by Eser Kucuker on 7.06.2025.
//

public struct GetUserResponse: Codable, Sendable {
    public let id: String?
    public let nameSurname: String?
    public let accessToken: String?
    public let refreshToken: String?
    public let pushNotificationEnabled: Bool?
    public let pushNotificationToken: String?
    public let kid: User.Kid?
    public let credit: UserCredit?

    public init(
        id: String? = nil,
        nameSurname: String? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        pushNotificationEnabled: Bool? = nil,
        pushNotificationToken: String? = nil,
        kid: User.Kid? = nil,
        credit: UserCredit? = nil
    ) {
        self.id = id
        self.nameSurname = nameSurname
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.pushNotificationEnabled = pushNotificationEnabled
        self.pushNotificationToken = pushNotificationToken
        self.kid = kid
        self.credit = credit
    }
}
