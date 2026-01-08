//
//  PaywallProvidable.swift
//  IAPKit
//
//  Created by IAPKit on 29.12.2024.
//

import SwiftUI
import UIKit

/// Protocol for fetchers that support remote paywall UI
/// Only RevenueCat supports this feature currently
@available(iOS 15.0, *) public protocol PaywallProvidable: AnyObject {
    /// Returns a SwiftUI PaywallView for the current placement
    /// Automatically fetches offerings if not already loaded
    /// - Parameter completion: Completion handler with the paywall view
    func getPaywallView(completion: @escaping (AnyView) -> Void)

    /// Returns a UIViewController for the paywall
    /// Automatically fetches offerings if not already loaded
    /// - Parameters:
    ///   - delegate: Optional delegate for paywall events
    ///   - completion: Completion handler with the view controller
    func getPaywallViewController(delegate: Any?, completion: @escaping (UIViewController) -> Void)
}
