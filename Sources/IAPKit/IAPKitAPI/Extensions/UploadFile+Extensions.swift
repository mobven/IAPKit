//
//  UploadFile+Extensions.swift
//  API
//
//  Created by Eser Kucuker on 14.06.2025.
//

import MBAsyncNetworkingV2

public extension FileV2 {
    var fileNameWithExtension: String {
        var fileName = fileName
        if !fileExtension.isEmpty {
            fileName.append(".")
            fileName.append(fileExtension)
        }
        return fileName
    }
}
