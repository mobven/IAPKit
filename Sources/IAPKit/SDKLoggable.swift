//
//  IAPKitLoggable.swift
//  IAPKit
//
//  Created by Hakan Kumdakçı on 16.07.2025.
//
import Foundation
import StoreKit

@available(iOS 15.0, *)
public struct IAPKitTransaction {
    public let transaction: Transaction
}

public protocol IAPKitLoggable: AnyObject {
    func logError(_ error: Error, context: String?)
    @available(iOS 15.0, *)
    func logTransaction(_ transaction: IAPKitTransaction)
    func log(_ message: String)
}

public enum IAPKitLogLevel {
    case prod, debug
    internal static var logLevel: IAPKitLogLevel = .prod
}

public extension IAPKitLoggable {
    func log(_ message: String) {
        #if DEBUG
        guard IAPKitLogLevel.logLevel == .debug else { return }
        print("[IAPKit] \(message)")
        #endif
    }
}
