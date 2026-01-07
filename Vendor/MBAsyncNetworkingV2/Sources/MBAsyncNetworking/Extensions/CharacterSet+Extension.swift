//
//  CharacterSet+Extension.swift
//  API
//
//  Created by Eser Kucuker on 8.01.2025.
//

import Foundation

/// Extensions for CharacterSet to assist with URL encoding
extension CharacterSet {
    /// CharacterSet for safely encoding URL query parameters according to RFC 3986
    ///
    /// This creates a character set that includes all characters allowed in URL query components
    /// according to RFC 3986, with exceptions for certain reserved characters that should be percent-encoded.
    ///
    /// RFC 3986 specifies the following reserved characters:
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// However, RFC 3986 Section 3.4 states that "?" and "/" should not be encoded in query strings
    /// to allow URLs to be included within query parameters.
    static let nwURLQueryAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
}
