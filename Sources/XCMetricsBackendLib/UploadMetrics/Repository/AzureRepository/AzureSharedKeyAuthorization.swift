//
//  AzureSharedKeyAuthorization.swift
//
//
//  Created by Diego Otero Díaz on 18/10/24.
//

import CryptoSwift
import Foundation
import Vapor

/// Azure Shared Key Authentication implementation.
/// See: https://learn.microsoft.com/en-us/rest/api/storageservices/authorize-with-shared-key
public struct AzureSharedKeyAuthorization {
    public let storageAccountName: String
    public let storageContainerName: String
    public let sharedKey: String
    public let fileName: String
    
    // Signature fields
    public let httpMethod: HTTPMethod
    public let contentEncoding: String?
    public let contentLanguage: String?
    public let contentLength: String?
    public let contentMD5: String?
    public let contentType: String?
    public let date: String?
    public let ifModifiedSince: String?
    public let ifMatch: String?
    public let ifNoneMatch: String?
    public let ifUnmodifiedSince: String?
    public let range: String?
    public let canonicalizedHeaders: CanonicalizedHeaders
    public var canonicalizedResource: String {
        "/\(storageAccountName)/\(storageContainerName)/\(fileName)"
    }
    
    private var stringToSign: String {
        return """
               \(httpMethod.string)
               \(contentEncoding ?? "")
               \(contentLanguage ?? "")
               \(contentLength ?? "")
               \(contentMD5 ?? "")
               \(contentType ?? "")
               \(date ?? "")
               \(ifModifiedSince ?? "")
               \(ifMatch ?? "")
               \(ifNoneMatch ?? "")
               \(ifUnmodifiedSince ?? "")
               \(range ?? "")
               \(canonicalizedHeaders.stringValue)
               \(canonicalizedResource)
               """
    }
    
    /// Base64 encoded signature
    public var signature: String {
        guard let keyData = Data(base64Encoded: sharedKey) else {
            return ""
        }
        
        return sha256HMAC(message: stringToSign, key: keyData)
    }
    
    /// Encodes and signs the message using the storage account's shared access key
    private func sha256HMAC(message: String, key: Data) -> String {
        let keyBytes = key.bytes
        let messageBytes = message.bytes
        let hmac = try! HMAC(key: keyBytes, variant: .sha256).authenticate(messageBytes)
        return Data(hmac).base64EncodedString()
    }
    
    public init(
        storageAccountName: String,
        storageContainerName: String,
        sharedKey: String,
        fileName: String,
        httpMethod: HTTPMethod,
        contentEncoding: String? = nil,
        contentLanguage: String? = nil,
        contentLength: String? = nil,
        contentMD5: String? = nil,
        contentType: String? = nil,
        date: String? = nil,
        ifModifiedSince: String? = nil,
        ifMatch: String? = nil,
        ifNoneMatch: String? = nil,
        ifUnmodifiedSince: String? = nil,
        range: String? = nil,
        canonicalizedHeaders: CanonicalizedHeaders
    ) {
        self.storageAccountName = storageAccountName
        self.storageContainerName = storageContainerName
        self.sharedKey = sharedKey
        self.fileName = fileName
        self.httpMethod = httpMethod
        self.contentEncoding = contentEncoding
        self.contentLanguage = contentLanguage
        self.contentLength = contentLength
        self.contentMD5 = contentMD5
        self.contentType = contentType
        self.date = date
        self.ifModifiedSince = ifModifiedSince
        self.ifMatch = ifMatch
        self.ifNoneMatch = ifNoneMatch
        self.ifUnmodifiedSince = ifUnmodifiedSince
        self.range = range
        self.canonicalizedHeaders = canonicalizedHeaders
    }
    
    public struct CanonicalizedHeaders {
        let stringValue: String
        
        public init(from httpHeaders: HTTPHeaders) {
            // Filter out the irrelevant headers
            var azureHeaders = httpHeaders.filter { $0.name.starts(with: "x-ms-") }
            azureHeaders.sort { $0.name < $1.name } // Sort in lexicographical order
            
            // Create the formatted string
            var tmp = [String]()
            azureHeaders.forEach { name, value in
                tmp.append("\(name):\(value)")
            }
            
            self.stringValue = tmp.joined(separator: "\n")
        }
    }
}
