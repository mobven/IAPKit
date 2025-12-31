//
//  PDNetworkable+logs.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import MBAsyncNetworking

final class NetworkMonitor: NetworkLogsDelegate, IAPKitLoggable {
    func logError(_ error: Error, context: String?) {
        #if DEBUG
        let message = context != nil ? "\(context!): \(error.localizedDescription)" : error.localizedDescription
        log(message)
        #endif
    }

    @available(iOS 15.0, *)
    func logTransaction(_ transaction: IAPKitTransaction) {
        // Not needed for network logs
    }
    func didReceiveError(request: URLRequest, error: Error?, log logMessage: String) {
        #if DEBUG
        let message = getRequestLog(request) + "\n" + (error?.localizedDescription ?? "")
        self.log("[ERROR] \(message)")
        #endif
    }

    func didReceiveResponse(request: URLRequest, data: Data?, log logMessage: String) {
        #if DEBUG
        let message = getRequestLog(request) + "\n" + getResponseLog(data)
        self.log(message)
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
