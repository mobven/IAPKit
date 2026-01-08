//
//  Error+Extension.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Extensions for Error type to assist with error handling
extension Error {
    /// Unwraps NSError objects to find underlying errors
    /// - Returns: The underlying error if found, or self if not
    var unwrappedErrorV2: Error {
        let error = self as NSError

        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return error
        }

        // If this is an NSError with NSUnderlyingError, unwrap it
        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? Error {
            return underlyingError.unwrappedErrorV2
        }

        // Special handling for authentication errors
        if error.domain == "com.alamofire.error" && error.code == 4,
           let data = error.userInfo["NSErrorFailingURLKey"] as? Data,
           let response = String(data: data, encoding: .utf8) {
            return NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: response])
        }

        return self
    }

    /// HTTP Status code for the related error.
    /// Retrieved by casting error to `MBErrorKit`'s `NetworkingError.httpError`
    var httpStatusCodeV2: Int? {
        (self as NSError).code
    }
}

/// Networking error codes
enum ErrorCodeV2 {
    /// 400 bad request.
    static let badRequest: Int = 400
    /// 401 unauthorized.
    static let unauthorized: Int = 401
}
