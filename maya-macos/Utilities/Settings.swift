//
//  Settings.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/29/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation
import Combine
import ServiceManagement

enum Settings {

    static let app = AppSettings.shared
    static let frame = FrameSettings.shared
    static let photos = PhotosSettings.shared
    static let localFolderProvider = LocalFolderProviderSettings.shared
    static let googlePhotos = GooglePhotosProviderSettings.shared
    static let applePhotos = ApplePhotosProviderSettings.shared
    static let appStoreReview = AppStoreReviewSettings.shared

    class ObservableSettings: ObservableObject {
        var notificationSubscription: AnyCancellable?

        fileprivate init() {
            notificationSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { _ in
                self.objectWillChange.send()
            }
        }
    }

    class AppSettings: ObservableSettings {
        fileprivate static let shared = AppSettings()

        @PublishedUserDefault("AppSettings.firstLaunch", defaultValue: true)
        var firstLaunch: Bool

        @PublishedUserDefault("AppSettings.openAtLogin", defaultValue: false)
        var openAtLogin: Bool

        @PublishedUserDefault("AppSettings.activeProvider", defaultValue: .none)
        var activeProvider: PhotoProviderType
    }

    class FrameSettings: ObservableSettings {
        fileprivate static let shared = FrameSettings()

        @PublishedUserDefault("FrameSettings.newPhotoAction", defaultValue: .popupFrame)
        var newPhotoAction: NewPhotoAction

        @PublishedUserDefault("FrameSettings..autoCloseFrame", defaultValue: false)
        var autoCloseFrame: Bool

        @PublishedUserDefault("FrameSettings.autoCloseFrameAfter", defaultValue: .seconds(10))
        var autoCloseFrameAfter: TimePeriod

        @PublishedUserDefault("FrameSettings.closeByOutsideClick", defaultValue: true)
        var closeByOutsideClick: Bool
    }

    class PhotosSettings: ObservableSettings {
        fileprivate static let shared = PhotosSettings()

        @PublishedUserDefault("PhotosSettings.autoSwitchPhoto", defaultValue: true)
        var autoSwitchPhoto: Bool

        @PublishedUserDefault("PhotosSettings.autoSwitchPhotoPeriod", defaultValue: .minutes(20))
        var autoSwitchPhotoPeriod: TimePeriod
    }

    class LocalFolderProviderSettings: ObservableSettings {
        fileprivate static let shared = LocalFolderProviderSettings()

        @PublishedUserDefault("LocalFolderProviderSettings.recentFolders", defaultValue: [])
        var recentFolders: [URL]

        @PublishedUserDefault("LocalFolderProviderSettings.bookmarks", defaultValue: [:])
        var bookmarks: [URL: Data]
    }

    class GooglePhotosProviderSettings: ObservableSettings {
        fileprivate static let shared = GooglePhotosProviderSettings()

        @PublishedUserDefault("GooglePhotosProviderSettings.activeAlbumId", defaultValue: nil)
        var activeAlbumId: String?
    }

    class ApplePhotosProviderSettings: ObservableSettings {
        fileprivate static let shared = ApplePhotosProviderSettings()

        @PublishedUserDefault("ApplePhotosProviderSettings.activeAlbumId", defaultValue: nil)
        var activeAlbumId: String?

        @PublishedUserDefault("ApplePhotoProviderSettings.trailPurchased", defaultValue: nil)
        var trialPurchasedData: [UInt8]?

        @PublishedUserDefault("ApplePhotoProviderSettings.fullPurchased", defaultValue: nil)
        var fullPurchasedData: [UInt8]?
    }

    class AppStoreReviewSettings: ObservableSettings {
        fileprivate static let shared = AppStoreReviewSettings()

        @PublishedUserDefault("AppStoreReviewSettings.lastReviewRequestDate", defaultValue: Date())
        var lastReviewRequest: Date

        @PublishedUserDefault("AppStoreReviewSettings.lastReviewVersion", defaultValue: "")
        var lastReviewVersion: String
    }
}

@propertyWrapper struct PublishedUserDefault<Value: Codable>: Publisher {
    typealias Output = Value
    typealias Failure = Never

    let key: String
    let defaultValue: Value
    private var publisher: CurrentValueSubject<Value, Never>?

    init(_ key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: Value {
        get {
            let object = UserDefaults.standard.object(forKey: key)
            // first try to decode object as property list
            // if that fails, value is most likely a basic type that can be cast directly to object
            if let data = object as? Data, let value = try? PropertyListDecoder().decode(Value.self, from: data) {
                return value
            }
            return (object as? Value) ?? defaultValue
        }
        set {
            publisher?.send(newValue)
            // first see if value is a property list convertible struct
            // if that fails, value is most likely a basic type that can be stored directly into user defaults
            let propList = try? PropertyListEncoder().encode(newValue)
            UserDefaults.standard.set(propList ?? newValue, forKey: key)
        }
    }

//    public var wrappedValue: Value {
//        get { fatalError() }
//        set { fatalError() }
//    }

//    public static subscript<EnclosingSelf: ObservableObject>(
//        _enclosingInstance instance: EnclosingSelf,
//        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
//        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> Value {
//        get {
//            let prop = instance[keyPath: storageKeyPath]
//            let object = UserDefaults.standard.object(forKey: prop.key)
//            // first try to decode object as property list
//            // if that fails, value is most likely a basic type that can be cast directly to object
//            if let data = object as? Data, let value = try? PropertyListDecoder().decode(Value.self, from: data) {
//                return value
//            }
//            return object as? Value ?? prop.defaultValue
//        }
//        set {
//            let prop = instance[keyPath: storageKeyPath]
//            prop.publisher?.send(newValue)
//            // first see if value is a property list convertible struct
//            // if that fails, value is most likely a basic type that can be stored directly into user defaults
//            let propList = try? PropertyListEncoder().encode(newValue)
//            UserDefaults.standard.set(propList ?? newValue, forKey: prop.key)
//        }
//    }

    // Allows for $ syntax to get publisher
    public var projectedValue: CurrentValueSubject<Value, Never> {
        mutating get {
            if let publisher = publisher {
                return publisher
            }
            let publisher = CurrentValueSubject<Value, Never>(wrappedValue)
            self.publisher = publisher
            return publisher
        }
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        publisher?.receive(subscriber: subscriber)
    }
}

enum NewPhotoAction: String, CaseIterable, PListCodable {
    case updateIcon
    case showNotification
    case popupFrame
}
