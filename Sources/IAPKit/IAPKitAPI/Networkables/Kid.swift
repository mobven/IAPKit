//
//  Kid.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation
import MBAsyncNetworking

public extension API {
    enum Kid: AsyncNetworkable {
        case create(request: CreateKidRequest)
        case profilePhoto(file: File)
        case updateKid(id: String, request: UpdateKidRequest)
        case getKid(id: String)

        public func request() async -> URLRequest {
            switch self {
            case let .create(request):
                await getRequest(url: API.getURL(withPath: "v1/kid/register"), encodable: request, httpMethod: .post)
            case let .profilePhoto(file):
                await uploadRequest(
                    url: API.getURL(withPath: "v1/kid/uploadProfilePhoto"),
                    parameters: ["filename": file.fileNameWithExtension],
                    files: [file]
                )
            case let .updateKid(id, request):
                await getRequest(url: API.getURL(withPath: "v1/kid/\(id)"), encodable: request, httpMethod: .post)
            case let .getKid(id):
                await getRequest(url: API.getURL(withPath: "v1/kid/\(id)"))
            }
        }
    }
}
