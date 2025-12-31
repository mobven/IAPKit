//
//  Credits.swift
//  API
//
//  Created by Cansu Özdizlekli on 8.12.2025.
//

import Foundation
import MBAsyncNetworking

public extension IAPKitAPI {
    enum Credits: AsyncNetworkable {
        case claimGiftCoins
        case getCredits
        case getProducts
        case purchase(request: PurchaseCreditRequest)

        public func request() async -> URLRequest {
            switch self {
            case .claimGiftCoins:
                await getRequest(
                    url: IAPKitAPI.getURL(withPath: "v1/users/me/claimGiftCoins"),
                    httpMethod: .get
                )
            case .getCredits:
                await getRequest(
                    url: IAPKitAPI.getURL(withPath: "v1/users/me/credits"),
                    httpMethod: .get
                )
            case .getProducts:
                await getRequest(
                    url: IAPKitAPI.getURL(withPath: "v1/users/me/creditProducts"),
                    httpMethod: .get
                )
            case let .purchase(request):
                await getRequest(
                    body: request,
                    url: IAPKitAPI.getURL(withPath: "v1/me/creditPurchase"),
                    httpMethod: .post
                )
            }
        }
    }
}
