//
//  AppResponse.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation

public struct AppResponse<T: Decodable>: Decodable {
    public var error: Bool
    public var reason: String?
    public var body: T?
}
