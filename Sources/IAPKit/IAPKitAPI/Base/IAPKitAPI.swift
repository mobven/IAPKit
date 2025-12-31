//
//  IAPKitAPI.swift
//  IAPKitAPI
//
//  Created by Eser Kucuker on 7.03.2025.
//

import Foundation

public enum IAPKitAPI {
    static func getURL(withPath path: String) -> URL {
        guard let baseURL = Bundle.main.stringFromInfoPlist("BACKEND_URL") else {
            fatalError("Could not init url")
        }
        guard let url = URL(string: "\(baseURL)\(path)") else {
            fatalError("Could not prepare url")
        }
        return url
    }

    static func getWSURL(withPath path: String) -> URL {
        guard let baseURL = Bundle.main.stringFromInfoPlist("BACKEND_URL")?.replacingOccurrences(of: "https", with: "wss") else {
            fatalError("Could not init url")
        }
        guard let url = URL(string: "\(baseURL)\(path)") else {
            fatalError("Could not prepare url")
        }
        return url
    }
}
