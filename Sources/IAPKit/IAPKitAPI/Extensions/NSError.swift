//
//  NSError.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation

public extension NSError {
    static func withLocalizedInfo(_ info: String) -> Error {
        NSError(domain: "API", code: -92, userInfo: [NSLocalizedDescriptionKey: info])
    }

    static var generic: Error {
        withLocalizedInfo("Error occurred while loading. Try again later.")
    }
}
