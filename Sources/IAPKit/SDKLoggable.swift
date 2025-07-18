//
//  IAPKitLoggable.swift
//  IAPKit
//
//  Created by Hakan Kumdakçı on 16.07.2025.
//
import Foundation

public protocol IAPKitLoggable: AnyObject {
    func logError(_ error: Error, context: String?)
}
