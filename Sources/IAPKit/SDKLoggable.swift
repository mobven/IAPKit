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
    let transaction: Transaction
}

public protocol IAPKitLoggable: AnyObject {
    func logError(_ error: Error, context: String?)
    @available(iOS 15.0, *)
    func logTransaction(_ transaction: IAPKitTransaction)
}
