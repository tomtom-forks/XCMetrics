//
//  +HTTPHeaders.swift
//
//
//  Created by Diego Otero Díaz on 18/10/24.
//

import Foundation
import Vapor

extension HTTPHeaders {
    public var azureSharedKeyAuthorization: AzureSharedKeyAuthorization? {
        get { nil } // We'll never need to use this with the current implementation
        set {
            if let authorization = newValue {
                replaceOrAdd(
                    name: .authorization,
                    value: "SharedKey \(authorization.storageAccountName):\(authorization.signature)"
                )
            } else {
                remove(name: .authorization)
            }
        }
    }
}

