//
//  Settings.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import ServiceManagement

extension Notification.Name {
    static let settingsNotification = Notification.Name("\(Bundle.main.bundleIdentifier!).Settings")
}

enum Settings {
    enum App {
        @UserDefault("\(Self.self).openAtLogin", defaultValue: false) static var openAtLogin: Bool {
            didSet {
                SMLoginItemSetEnabled(launcherAppId as CFString, openAtLogin)
                print("Key \(self.openAtLogin)")
            }
        }
    }
    
    enum Frame {
        @UserDefault("\(Self.self).popupFrame", defaultValue: false) static var popupFrame: Bool
        @UserDefault("\(Self.self).autoCloseFrame", defaultValue: false) static var autoCloseFrame: Bool
        @UserDefault("\(Self.self).autoCloseFrameAfter", defaultValue: .seconds(10)) static var autoCloseFrameAfter: TimePeriod
    }
    
    enum Photos {
        @UserDefault("\(Self.self).autoSwitchPhoto", defaultValue: true) static var autoSwitchPhoto: Bool {
            didSet {
                print("Sending notification: \(autoSwitchPhoto)")
                NotificationCenter.default.post(name: .settingsNotification, object: autoSwitchPhoto)
            }
        }
        @UserDefault("\(Self.self).autoSwitchPhotoPeriod", defaultValue: .minutes(10)) static var autoSwitchPhotoAfter: TimePeriod
        
    }
}

@propertyWrapper struct UserDefault<T: Codable> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            let object = UserDefaults.standard.object(forKey: key)
            // first try to decode object as property list
            // if that fails, value is most likely a basic type that can be cast directly to object
            if let data = object as? Data, let value = try? PropertyListDecoder().decode(T.self, from: data) {
                return value
            }
            return object as? T ?? defaultValue
        }
        set {
            // first see if value is a property list convertible struct
            // if that fails, value is most likely a basic type that can be stored directly into user defaults
            let propList = try? PropertyListEncoder().encode(newValue)
            UserDefaults.standard.set(propList ?? newValue, forKey: key)
        }
    }
}

@propertyWrapper struct Notifying<T> {
    private var value: T
    
    var wrappedValue: T {
        get {
            return value
        }
        set {
//            NotificationCenter.default.post(name: <#T##NSNotification.Name#>, object: <#T##Any?#>)
        }
    }
}
