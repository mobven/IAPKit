//
//  AsyncNetworkable+logs.swift
//  API
//
//  Created by Eser Kucuker on 06.01.2024.
//

import Foundation
import MobKitCore
import OSLog

@available(iOS 14.0, *) let logger = Logger(subsystem: "MBAsyncNetworking", category: "Network Logs")

/// Extension that provides logging functionality for network requests and responses
extension AsyncNetworkableV2 {
    /// Prints the response data to the console for debugging purposes.
    /// Also notifies the NetworkLogsManager delegate with the response data and the generated log.
    /// - Parameters:
    ///   - data: The response data to log. Can be `nil`.
    ///   - request: The original URL request associated with the response.
    func printResponse(_ data: Data?, request: URLRequest) {
        let logString = getRequestLog(request) + "\n" + getStringFrom(data)
        printLog(logString)
        NetworkLogsManagerV2.shared.delegate?.didReceiveResponse(
            request: request,
            data: data,
            log: logString
        )
    }

    /// Prints error details to the console.
    /// Also notifies the NetworkLogsManager delegate with the error information and the generated log.
    /// - Parameters:
    ///   - error: The error encountered during the request. Can be `nil`.
    ///   - request: The original URL request that resulted in an error.
    func printErrorLog(_ error: Error?, request: URLRequest) {
        let logString = getRequestLog(request) + "\n" + (error?.localizedDescription ?? "")
        printLog(logString, level: .error)
        NetworkLogsManagerV2.shared.delegate?.didReceiveError(
            request: request,
            error: error,
            log: logString
        )
    }

    /// Builds a formatted string containing request details for logging purposes.
    /// Includes the request URL, headers, and optionally the request body if available.
    /// - Parameter request: The `URLRequest` to extract logging information from.
    /// - Returns: A formatted string containing the request URL, headers, and body.
    private func getRequestLog(_ request: URLRequest) -> String {
        var log = "Endpoint: \(request.url?.absoluteString ?? "")"
        log.append("\n")
        log.append("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            log.append("\n")
            log.append("Request Body:")
            log.append(getStringFrom(body))
        }
        return log
    }

    /// Prints a log message to the console with the specified log level
    /// - Parameters:
    ///   - log: The string to log
    ///   - level: The OSLogType level (defaults to .info)
    func printLog(_ log: String, level: OSLogType = .info) {
        if MobKit.isDeveloperModeOn {
            if #available(iOS 14.0, *) {
                logger.log(level: level, "\(log)")
            } else {
                print(log)
            }
        }
    }

    /// Converts Data to a readable string representation
    /// - Parameter data: The data to convert
    /// - Returns: String representation of the data (pretty-printed if JSON)
    private func getStringFrom(_ data: Data?) -> String {
        if let data {
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
               !(jsonObject is NSNull),
               let json = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let string = String(data: json, encoding: .utf8) {
                return string
            } else if let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
        return ""
    }
}
