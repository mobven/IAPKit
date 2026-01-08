//
//  Credits.swift
//  API
//
//  Created by Cansu Özdizlekli on 8.12.2025.
//

import Foundation

public extension IAPKitAPI {
    enum Credits: AsyncNetworkableV2 {
        case claimGiftCoins
        case getCredits
        case getProducts
        case spendCredit(request: SpendCreditRequest)

        public func request() async -> URLRequest {
            switch self {
            case .claimGiftCoins:
                await getRequest(
                    url: IAPKitAPI.getURL(withPath: "api/v1/users/me/credits/claim-gift"),
                    httpMethod: .post
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
            case let .spendCredit(request):
                await getRequest(
                    body: request,
                    url: IAPKitAPI.getURL(withPath: "api/v1/users/me/credits/spend"),
                    httpMethod: .post
                )
            }
        }
    }
}
