//
//  PDNetworkable+logs.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import MBAsyncNetworking
import OSLog

@available(iOS 14.0, *)
let logger = Logger(subsystem: "API", category: "API Logs")

final class NetworkMonitor: NetworkLogsDelegate {
    func didReceiveError(request: URLRequest, error: Error?, log: String) {
        #if DEBUG
        printLog(getRequestLog(request) + "\n" + (error?.localizedDescription ?? ""), level: .error)
        #endif
    }

    func didReceiveResponse(request: URLRequest, data: Data?, log: String) {
        #if DEBUG
        printLog(getRequestLog(request) + "\n" + getResponseLog(data))
        #endif
    }

    private func getRequestLog(_ request: URLRequest) -> String {
        var log = "Endpoint: \(request.url?.absoluteString ?? "")"
        log.append("\n")
        log.append("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            log.append("\n")
            log.append("Request Body: ")
            log.append(getStringFrom(body))
        }
        return log
    }

    private func getResponseLog(_ data: Data?) -> String {
        var log = ""
        log.append("Response Body: ")
        log.append(getStringFrom(data))
        return log
    }

    func printLog(_ log: String, level: OSLogType = .info) {
        if #available(iOS 14.0, *) {
            logger.log(level: level, "\(log)")
        } else {
            print(log)
        }
    }

    private func getStringFrom(_ data: Data?) -> String {
        guard let data else { return "- " }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
           !(jsonObject is NSNull),
           let json = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let jsonString = String(data: json, encoding: .utf8) {
            return jsonString
        }

        return String(data: data, encoding: .utf8) ?? "- "
    }
}
