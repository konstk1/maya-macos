//
//  PhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/1/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import Combine

class PhotoProvider: ObservableObject {
    let id = UUID()
    
    @Published var photoDescriptors: [PhotoAssetDescriptor] = []
    @Published var albumList: [String] = []

    @Published var error: PhotoProviderError?

    /// `enum` value describing type of photo provider (used for savings to UserDefaults)
    var type: PhotoProviderType {
        switch self {
        case is LocalFolderPhotoProvider:
            return .localFolder
        case is GooglePhotoProvider:
            return .googlePhotos
        default:
            fatalError("Unimplemented photo provider type")
        }
    }

    /// To be implemented by each subclass
    @discardableResult
    func refreshAssets() -> Future<[PhotoAssetDescriptor], PhotoProviderError> {
        fatalError("refreshAssets not implemented for this class")
    }
}

protocol PhotoAssetDescriptor: CustomStringConvertible {
    // fetches an image for underlying photo asset
    func fetchImage(using provider: PhotoProvider) -> Future<NSImage, PhotoProviderError>
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
