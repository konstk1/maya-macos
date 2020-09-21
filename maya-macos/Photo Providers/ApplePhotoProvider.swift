//
//  ApplePhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine
import Photos

final class ApplePhotoProvider: PhotoProvider {

    private(set) var albums: [PHAssetCollection] = [] {
        didSet {
            albumsPublisher.send(albums)
        }
    }
    var albumsPublisher = CurrentValueSubject<[PHAssetCollection], Never>([])

    private var activeAlbum: PHAssetCollection?

    /// Photos in active album
    private var photos: [PHAsset] = [] {
        didSet {
            photoDescriptors = photos.map { ApplePhotoAsset(asset: $0) }
            NotificationCenter.default.post(name: .updatePhotoCount, object: self, userInfo: ["photoCount": photos.count])
        }
    }

    @Published private(set) var authStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()

    override init() {
        super.init()

        log.info("Apple Photos provider init")
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func authorize() {
        PHPhotoLibrary.shared().register(self)
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            log.verbose("Auth status: \(status.rawValue)")
            self?.authStatus = status
        }
    }

    func setActiveAlbum(album: PHAssetCollection) {
        // persist active album selection
        activeAlbum = album
        Settings.applePhotos.activeAlbumId = album.localIdentifier
        log.info("Setting active album to \(album.localizedTitle ?? "") id \(album.localIdentifier)")
        photos = listPhotos(for: album)     // fetch photos in active album
    }

    func getActiveAlbum() -> PHAssetCollection? {
        if activeAlbum == nil {
            // list albums and find active album in albums
            listAlbums()

            if let activeAlbumId = Settings.applePhotos.activeAlbumId {
                activeAlbum = albums.first { $0.localIdentifier == activeAlbumId}
            } else {
                activeAlbum = albums.first
            }
        }

        log.info("Getting active album: \(activeAlbum?.localizedTitle ?? "")")

        return activeAlbum
    }

    private func makeCollectionOfAll() -> PHAssetCollection {
        let result = PHAsset.fetchAssets(with: .image, options: nil)
        let collection = PHAssetCollection.transientAssetCollection(withAssetFetchResult: result, title: "All")
        // transient collections have random identifier, which makes it impossible to save
        // set localIdentifer (uuid) here so localIdentifier is constant for this collection
        collection.setValue("apple.photos.transient.all", forKey: "uuid")
        return collection
    }

    @discardableResult
    func listAlbums() -> [PHAssetCollection] {
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)

        var collections: [PHAssetCollection] = [makeCollectionOfAll()]      // first collection is of ALL photos

        for i in 0..<fetchResult.count {
            let collection = fetchResult.object(at: i)
            collections.append(collection)
        }

        albums = collections

        return albums
    }

    func listPhotos(for album: PHAssetCollection) -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let fetchResult = PHAsset.fetchAssets(in: album, options: options)

        var assets: [PHAsset] = []

        for i in 0..<fetchResult.count {
            assets.append(fetchResult.object(at: i))
        }

        return assets
    }

    func getPhoto(asset: PHAsset) -> Future<NSImage, PhotoProviderError> {
        return Future { promise in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.resizeMode = .fast
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
                guard let image = image else {
                    promise(.failure(.unknown))
                    return
                }

                promise(.success(image))
            }
        }
    }

    @discardableResult
    override func refreshAssets() -> Future<[PhotoAssetDescriptor], PhotoProviderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return

            }
            guard self.authStatus == .authorized else {
                promise(.failure(.unauthorized))
                return
            }
            guard let activeAlbum = self.getActiveAlbum() else {
                promise(.failure(.noActiveAlbum))
                return
            }

            self.photos = self.listPhotos(for: activeAlbum)
            promise(.success(self.photoDescriptors))
        }
    }
}

extension ApplePhotoProvider: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("Lib did change")
        if let activeAlbum = getActiveAlbum() {
            photos = listPhotos(for: activeAlbum)
        }
    }
}

struct ApplePhotoAsset: PhotoAssetDescriptor {
    var location: CLLocation? {
        asset.location
    }

    var creationDate: Date? {
        asset.creationDate
    }

    var asset: PHAsset
    var description: String { "Apple asset type \(asset.localIdentifier) (\(asset.pixelWidth)x\(asset.pixelHeight))" }

    func fetchImage(using provider: PhotoProvider) -> Future<NSImage, PhotoProviderError> {
        guard let provider = provider as? ApplePhotoProvider else {
            log.error("Invalid provider for \(self)")
            return Future { $0(.failure(PhotoProviderError.unknown)) }
        }

        return provider.getPhoto(asset: asset)
    }
}
