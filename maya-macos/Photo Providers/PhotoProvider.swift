//
//  PhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/1/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import Combine

protocol PhotoProvider: class {
    var id: UUID { get }

    var photoDescriptors: [PhotoAssetDescriptor] { get }
    var photoDescriptorsPublisher: CurrentValueSubject<[PhotoAssetDescriptor], Error> { get }
    func refreshAssets() -> Future<[PhotoAssetDescriptor], Error>
}

extension PhotoProvider {
    /// enum value describing type of photo provider (used for savings to UserDefaults)
    var type: PhotoProviderType {
        switch self {
        case is LocalFolderPhotoProvider:
            return .localFolder
        case is GooglePhotoProvider:
            return .googlePhotos
        default:
            log.warning("Unimplemented photo provider type")
            return .none
        }
    }
}

protocol PhotoAssetDescriptor: CustomStringConvertible {
    // fetches an image for underlying photo asset
    func fetchImage() -> Future<NSImage, Error>
}

enum PhotoProviderType: String, PListCodable {
    case none = "none"
    case localFolder = "localFolder"
    case googlePhotos = "googlePhotos"
}

enum PhotoProviderError: Error {
    case failedReadLocalFile
    case failedFetchURL
    case failedAuth
    case noActiveAlbum
    case unknown
}

extension Notification.Name {
    static let updatePhotoCount = Notification.Name("updatePhotoCount")
}
