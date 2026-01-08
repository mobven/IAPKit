//
//  UploadFile.swift
//  API
//
//  Created by Eser Küçüker on 7/01/25.
//

import Foundation

/// Represents a file to be uploaded in a multipart form data request
struct FileV2 {
    /// Key name for the file in the multipart form data
    var name: String
    /// Name of the file without extension
    var fileName: String
    /// Extension of the file (without the dot)
    var fileExtension: String
    /// MIME type of the file (e.g., "image/jpeg")
    var mimeType: String
    /// The binary data of the file
    var data: Data

    /// The complete filename with extension
    var fileNameWithExtension: String {
        var fileName = fileName
        if !fileExtension.isEmpty {
            fileName.append(".")
            fileName.append(fileExtension)
        }
        return fileName
    }

    /// Initialize a new File for multipart upload
    /// - Parameters:
    ///   - name: Key of multipart form data
    ///   - fileName: Name of the file without extension
    ///   - fileExtension: Extension of the file (without the dot)
    ///   - mimeType: MIME type of the file (e.g., "image/jpeg")
    ///   - data: The binary data of the file
    init(name: String, fileName: String, fileExtension: String, mimeType: String, data: Data) {
        self.name = name
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.data = data
    }
}
