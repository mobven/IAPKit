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
        case spendCredit(request: SpendCreditRequest)

        public func request() async -> URLRequest {
            switch self {
            case .claimGiftCoins:
                await getRequest(
                    url: IAPKitAPI.getURL(withPath: "api/v1/users/me/credits/claim-gift"),
                    httpMethod: .get
                )
            case .getCredits:
                await getRequest(
                    url: IAPKitAPI.getURL(withPath: "api/v1/users/me/credits"),
                    httpMethod: .get
                )
            case .getProducts:
                await getRequest(
                    url: IAPKitAPI.getURL(withPath: "api/v1/products/list"),
                    httpMethod: .get
                )
            case .spendCredit(let request):
                await getRequest(
                    body: request,
                    url: IAPKitAPI.getURL(withPath: "api/v1/users/me/credits/spend"),
                    httpMethod: .post
                )
            }
        }
    }
}
