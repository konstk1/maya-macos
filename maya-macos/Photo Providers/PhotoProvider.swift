//
//  PhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/1/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine

class PhotoProvider: NSObject, ObservableObject {
    let id = UUID()

    @Published var photoDescriptors: [PhotoAssetDescriptor] = []
    @Published var albumList: [String] = []

    @Published var error: PhotoProviderError = .none

    /// `enum` value describing type of photo provider (used for savings to UserDefaults)
    var type: PhotoProviderType {
        switch self {
        case is LocalFolderPhotoProvider:
            return .localFolder
        case is GooglePhotoProvider:
            return .googlePhotos
        case is ApplePhotoProvider:
            return .applePhotos
        default:
            fatalError("Unimplemented photo provider type")
        }
    }

    /// To be implemented by each subclass
    @discardableResult
    func refreshAssets() -> Future<[PhotoAssetDescriptor], PhotoProviderError> {
        fatalError("refreshAssets not implemented for this class")
    }

//    static func == (lhs: PhotoProvider, rhs: PhotoProvider) -> Bool {
//        return lhs.id == rhs.id
//    }
}

protocol PhotoAssetDescriptor: CustomStringConvertible {
    // fetches an image for underlying photo asset
    func fetchImage(using provider: PhotoProvider) -> Future<NSImage, PhotoProviderError>
}

enum PhotoProviderType: String, PListCodable {
    case none
    case localFolder
    case googlePhotos
    case applePhotos
}

enum PhotoProviderError: Error {
    case none
    case failedReadLocalFile
    case failedFetchURL
    case failedAuth
    case unauthorized
    case noActiveAlbum
    case failedToListAlbums
    case unknown

    var localizedDescription: String {
        switch self {
        case .none: return "None"
        case .failedReadLocalFile: return "Failed to read local file"
        case .failedFetchURL: return "Failed to fetch URL"
        case .failedAuth: return "Failed auth"
        case .unauthorized: return "Unauthorized"
        case .noActiveAlbum: return "No active album"
        case .failedToListAlbums: return "Failed to list albums"
        case .unknown: return "Unknown"
        }
    }
}

extension Notification.Name {
    static let updatePhotoCount = Notification.Name("updatePhotoCount")
}
