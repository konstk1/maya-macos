//
//  Settings.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

enum Settings {
    enum App {
        @UserDefault("\(Self.self).openAtLogin", defaultValue: false) static var openAtLogin: Bool {
            didSet {
                print("New val \(openAtLogin)")
            }
        }
    }
    
    enum Frame {
        @UserDefault("\(Self.self).popupFrame", defaultValue: false) static var popupFrame: Bool
        @UserDefault("\(Self.self).autoCloseFrame", defaultValue: false) static var autoCloseFrame: Bool
        @UserDefaultCodable("\(Self.self).autoCloseFrameAfter", defaultValue: .seconds(10)) static var autoCloseFrameAfter: TimePeriod
    }
    
    enum Photos {
        @UserDefault("\(Self.self).autoSwitchPhoto", defaultValue: true) static var autoSwitchPhoto: Bool
        @UserDefaultCodable("\(Self.self).autoSwitchPhotoPeriod", defaultValue: .minutes(10)) static var autoSwitchPhotoAfter: TimePeriod
        
    }
}

@propertyWrapper struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper struct UserDefaultCodable<T: Codable> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            if let data = UserDefaults.standard.value(forKey: key) as? Data,
               let value = try? PropertyListDecoder().decode(T.self, from: data) {
                return value
            }
            return defaultValue
        }
        set {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(newValue), forKey: key)
        }
    }
}
