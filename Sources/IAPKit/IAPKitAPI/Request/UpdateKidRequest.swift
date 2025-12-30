//
//  UpdateKidRequest.swift
//  API
//
//  Created by Emin Çelikkan on 13.06.2025.
//

import Foundation

public struct UpdateKidRequest: Encodable {
    public let name: String
    public let birthDate: Date
    public let gender: String?

    public init(name: String, birthdate: Date, gender: String?) {
        self.name = name
        birthDate = birthdate
        self.gender = gender
    }
}
