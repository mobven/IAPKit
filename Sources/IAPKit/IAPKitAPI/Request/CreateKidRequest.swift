//
//  CreateKidRequest.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation

public struct CreateKidRequest: Encodable {
    public let name: String
    public let birthDate: Date
    public let gender: String?

    public init(name: String, birthdate: Date, gender: String?) {
        self.name = name
        birthDate = birthdate
        self.gender = gender
    }
}

public struct CreateKidResponse: Decodable, Sendable {
    public let name: String
    public let birthDate: Date
    public let gender: String?
    public let photoURL: String?
    public let id: String?

    public init(name: String, birthDate: Date, gender: String? = nil, id: String? = nil, photoURL: String? = nil) {
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.id = id
        self.photoURL = photoURL
    }
}
