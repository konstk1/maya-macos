//
//  Settings.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import ServiceManagement

enum Settings {

    static let app = AppSettings.shared
    static let frame = FrameSettings.shared
    static let photos = PhotosSettings.shared
    static let localFolderProvider = LocalFolderProviderSettings.shared
    
    class AppSettings: NSObject {
        fileprivate static let shared = AppSettings()
        private override init() { super.init() }
        
        @UserDefault(makeKey(type: AppSettings.self, keypath: \.openAtLogin), defaultValue: false) @objc dynamic var openAtLogin: Bool {
            didSet {
                // TODO: move this to app delegate
                SMLoginItemSetEnabled(launcherAppId as CFString, openAtLogin)
            }
        }
    }
    
    class FrameSettings: NSObject {
        fileprivate static let shared = FrameSettings()
        private override init() { super.init() }
        
        @UserDefault(makeKey(type: FrameSettings.self, keypath: \.popupFrame), defaultValue: false)
        @objc dynamic var popupFrame: Bool
        
        @UserDefault(makeKey(type: FrameSettings.self, keypath: \.autoCloseFrame), defaultValue: false)
        @objc dynamic var autoCloseFrame: Bool
        
        @UserDefault(makeKey(type: FrameSettings.self, keypath: \.autoCloseFrameAfter), defaultValue: .seconds(10))
        @objc dynamic var autoCloseFrameAfter: TimePeriod
    }
    
    class PhotosSettings: NSObject {
        fileprivate static let shared = PhotosSettings()
        private override init() { super.init() }
        
        @UserDefault(makeKey(type: PhotosSettings.self, keypath: \.autoSwitchPhoto), defaultValue: true)
        @objc dynamic var autoSwitchPhoto: Bool
        
        @UserDefault(makeKey(type: PhotosSettings.self, keypath: \.autoSwitchPhotoPeriod), defaultValue: .minutes(10))
        @objc dynamic var autoSwitchPhotoPeriod: TimePeriod
    }
    
    class LocalFolderProviderSettings: NSObject {
        fileprivate static let shared = LocalFolderProviderSettings()
        private override init() { super.init() }
        
        @UserDefault(makeKey(type: LocalFolderProviderSettings.self, keypath: \.recentFolders), defaultValue: [])
        @objc dynamic var recentFolders: [URL]
        
        @UserDefault(makeKey(type: LocalFolderProviderSettings.self, keypath: \.bookmarks), defaultValue: [:])
        @objc dynamic var bookmarks: [URL: Data]
    }
    
    /// Makes UserDefaults key from type and keypath.
    /// - Warning: `keypath` must reference an `@objc` property,
    /// otherwise `_kvcKeyPathString` is nil and app will abort.
    /// This is intentional because there is no default behavior to save such a value.
    private static func makeKey<T,U>(type: T.Type, keypath: KeyPath<T,U>) -> String {
        guard let keyPathString = keypath._kvcKeyPathString else {
            fatalError("Attempt to make key from non-@objc property!")
        }
        return "\(type).\(keyPathString)"
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

