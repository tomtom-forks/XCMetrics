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
        get { nil } // Not really necessary
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

