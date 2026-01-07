//
//  IAP.swift
//  IAPKit
//
//  //  Created by Cansu Özdizlekli on 5.01.2026.
//

import Foundation

public extension IAPKitAPI {
    enum IAP: AsyncNetworkableV2 {
        case buy(request: ReceiptValidationRequest)
        case restore(request: ReceiptValidationRequest)

        public func request() async -> URLRequest {
            switch self {
            case let .buy(request):
                await getRequest(
                    body: request,
                    url: IAPKitAPI.getURL(withPath: "api/v1/iap/adapty/buy"),
                    httpMethod: .post
                )
            case let .restore(request):
                await getRequest(
                    body: request,
                    url: IAPKitAPI.getURL(withPath: "api/v1/iap/adapty/restore"),
                    httpMethod: .post
                )
            }
        }
    }
}
