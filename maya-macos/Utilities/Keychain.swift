//
//  Keychain.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import KeychainAccess

//fileprivate let keychain = Keychain(service: Bundle.main.bundleIdentifier!).accessibility(.afterFirstUnlock)

@propertyWrapper struct KeychainSecureString {
    let key: String
    
    var wrappedValue: String? {
        get {
//            keychain[key]
            ""
        }
        set {
//            keychain[key] = newValue
        }
    }
    
}
