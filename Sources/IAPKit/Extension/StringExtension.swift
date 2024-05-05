//
//  StringExtension.swift
//
//
//  Created by Eser Kucuker on 18.04.2024.
//

import Foundation
import UIKit

extension String? {
    var isNilOrEmpty: Bool {
        self == nil || self == ""
    }
}

/// Allows to match for optionals with generics that are defined as non-optional.
public protocol AnyOptional {
    /// Returns `true` if `nil`, otherwise `false`.
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    public var isNil: Bool { self == nil }
}
