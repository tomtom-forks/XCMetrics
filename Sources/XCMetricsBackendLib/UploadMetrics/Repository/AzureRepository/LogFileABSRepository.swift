// Copyright (c) 2020 Spotify AB.
//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation
import Vapor

/// `LogFileRepository` that uses Azure Blob Storage to store and fetch logs
struct LogFileABSRepository: LogFileRepository {
    let storageAccountName: String
    let storageContainerName: String
    let storageAccountAccessKey: String
    
    let client: Client

    init(
        storageAccountName: String,
        storageContainerName: String,
        storageAccountAccessKey: String,
        client: Client
    ) {
        self.storageAccountName = storageAccountName
        self.storageContainerName = storageContainerName
        self.storageAccountAccessKey = storageAccountAccessKey
        self.client = client
    }

    init?(config: Configuration, client: Client) {
        guard
            let storageAccountName = config.azureStorageAccount,
            let storageContainerName = config.azureStorageContainer,
            let storageAccountAccessKey = config.azureStorageAccountAccessKey
        else {
            return nil
        }
        
        self.init(
            storageAccountName: storageAccountName,
            storageContainerName: storageContainerName,
            storageAccountAccessKey: storageAccountAccessKey,
            client: client
        )
    }

    func put(logFile: File) throws -> URL {
        let fileName = logFile.filename
        let fileData = Data(logFile.data.xcm_onlyFileData().readableBytesView)
        let logURLString = "https://\(storageAccountName).blob.core.windows.net/\(storageContainerName)/\(fileName)"
        let logURI = URI(string: logURLString)
        
        // Create headers
        let rfc1123DateString = getRFC1123DateString()
        let contentLength = String(Int64(fileData.count))
        let headers = HTTPHeaders([
            ("Date", rfc1123DateString),
            ("Content-Length", contentLength),
            ("x-ms-blob-type", "BlockBlob"),
            ("x-ms-version", "2025-01-05"),
        ])
        
        // Configure and send authorized PUT request with the file
        let response = try client.put(logURI, headers: headers) { req in
            req.body = logFile.data.xcm_onlyFileData()
            req.headers.azureSharedKeyAuthorization = AzureSharedKeyAuthorization(
                storageAccountName: storageAccountName,
                storageContainerName: storageContainerName,
                sharedKey: storageAccountAccessKey,
                fileName: fileName,
                httpMethod: .PUT,
                contentLength: contentLength,
                date: rfc1123DateString,
                canonicalizedHeaders: .init(from: headers)
            )
        }.wait()
        
        guard response.status == .created else {
            throw RepositoryError.unexpected(message: "Failed to upload log \(fileName) to Azure Blob Storage.")
        }
        
        return URL(string: logURLString)!
    }

    func get(logURL: URL) throws -> LogFile {
        let fileName = logURL.lastPathComponent
        let logURI = URI(string: logURL.absoluteString)
        
        // Create headers
        let rfc1123DateString = getRFC1123DateString()
        let headers = HTTPHeaders([
            ("Date", rfc1123DateString),
            ("x-ms-version", "2025-01-05"),
        ])
        
        // Configure and send authorized GET request for the file
        let response = try client.get(logURI, headers: headers) { req in
            req.headers.azureSharedKeyAuthorization = AzureSharedKeyAuthorization(
                storageAccountName: storageAccountName,
                storageContainerName: storageContainerName,
                sharedKey: storageAccountAccessKey,
                fileName: fileName,
                httpMethod: .GET,
                date: rfc1123DateString,
                canonicalizedHeaders: .init(from: headers)
            )
        }.wait()
        
        guard
            response.status == .ok,
            let responseBody = response.body
        else {
            throw RepositoryError.unexpected(message: "There was an error downloading file \(logURL)")
        }
        
        // Read data from response and write it to a temporary local file
        let data = Data(responseBody.readableBytesView)
        let tmp = try TemporaryFile(creatingTempDirectoryForFilename: "\(UUID().uuidString).xcactivitylog")
        try data.write(to: tmp.fileURL)
        
        return LogFile(remoteURL: logURL, localURL: tmp.fileURL)
    }
    
    private func getRFC1123DateString(for date: Date = .now) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        
        return dateFormatter.string(from: date)
    }
}
