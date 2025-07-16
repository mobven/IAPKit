//
//  SDKLoggable.swift
//  IAPKit
//
//  Created by Hakan Kumdakçı on 16.07.2025.
//
import Foundation

public protocol SDKLoggable: AnyObject {
    func logError(_ error: Error, context: String?)
}
