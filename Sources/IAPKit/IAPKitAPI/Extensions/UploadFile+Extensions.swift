//
//  UploadFile+Extensions.swift
//  API
//
//  Created by Eser Kucuker on 14.06.2025.
//

import MBAsyncNetworking

public extension File {
    var fileNameWithExtension: String {
        var fileName = fileName
        if !fileExtension.isEmpty {
            fileName.append(".")
            fileName.append(fileExtension)
        }
        return fileName
    }
}
