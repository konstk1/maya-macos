//
//  LocalFolderPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine
import CoreLocation

final class LocalFolderPhotoProvider: PhotoProvider {
    /// List of recently used folders
    var recentFolders: [URL] {
        Settings.localFolderProvider.recentFolders
    }

    /// Whether or not to look into sub-folders while looking for photos
    var descendIntoSubfolders = false   // TODO: implement this

    /// List of photos in active folder
    private var photoURLs: [URL] = [] {
        didSet {
            NotificationCenter.default.post(name: .updatePhotoCount, object: self, userInfo: ["photoCount": photoURLs.count])
            photoDescriptors = photoURLs.map { LocalPhotoAsset(photoURL: $0) }
        }
    }

    /// Supported photo file extensions
    private let supportedExtension = ["png", "jpg", "jpeg"]

    private let fileManager = FileManager.default

    private var activeFolder: URL = URL(fileURLWithPath: "")
    private var isAccessingSecuredResource = false

    override init() {
        super.init()

        print("LocalPhotoProvider init")

        guard let lastActiveFolder = Settings.localFolderProvider.recentFolders.first else { return }

        do {
            activeFolder = try loadBookmark(for: lastActiveFolder)
            photoURLs = try updatePhotoList()
        } catch let error as PhotoProviderError {
            log.error("Failed initialize Local Folder provider: \(error)")
            self.error = error
        } catch {
            log.error("Failed initialize Local Folder provider: \(error)")
            self.error = .unknown
        }
    }

    deinit {
        stopFolderAccess()
    }

    func setActiveFolder(url: URL) throws {
        log.info("Setting folder URL: \(url.path)")

        // check if url has bookmark data
        if let bookmarkData = try? url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess]) {
            Settings.localFolderProvider.bookmarks[url] = bookmarkData
            activeFolder = url
        } else {
            // load bookmark from settings
            activeFolder = try loadBookmark(for: url)
        }

        photoURLs = (try? updatePhotoList()) ?? []

        // save most recent folders
        updateRecents(with: url)
    }

    private func loadBookmark(for url: URL) throws -> URL {
        guard let bookmarkData = Settings.localFolderProvider.bookmarks[url] else {
            log.error("No bookmark found for \(url.path)")
            throw LocalFolderProviderError.bookmarkFailure
        }

        var isStale: Bool = false
        let bookmarkedUrl = try URL(resolvingBookmarkData: bookmarkData, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)

        if isStale {
            log.warning("Stale bookmark for \(bookmarkedUrl.path)")
        }

        return bookmarkedUrl
    }

    func startFolderAccess() throws {
        isAccessingSecuredResource = activeFolder.startAccessingSecurityScopedResource()
        if isAccessingSecuredResource {
            log.verbose("Start access to secured: \(activeFolder.path)")
        }
    }

    func stopFolderAccess() {
        if isAccessingSecuredResource {
            activeFolder.stopAccessingSecurityScopedResource()
            log.verbose("Stop access to secured: \(activeFolder.path)")
        }
    }

    private func saveBookmark(for url: URL) {
        do {
            Settings.localFolderProvider.bookmarks[url] = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
        } catch {
            log.error("Failed to save bookmark for \(url.path)")
        }
    }

    private func updateRecents(with url: URL) {
        let maxRecentFolders = 5
        var recents = Settings.localFolderProvider.recentFolders

        // if url exists in recent list, remove it to avoid duplicates
        // then add url to the front of the list and clip the list to max items
        recents.removeAll { $0 == url}
        recents.insert(url, at: 0)
        if recents.count > maxRecentFolders {
            recents.removeSubrange(maxRecentFolders...)
        }

        Settings.localFolderProvider.recentFolders = recents
    }

    private func updatePhotoList() throws -> [URL] {
        try startFolderAccess()
        defer {
            stopFolderAccess()
        }
        let urls = try fileManager.contentsOfDirectory(at: activeFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
        return urls.filter { supportedExtension.contains($0.pathExtension) }
    }

    internal func clearPhotoAssets() {
        photoURLs.removeAll()
    }

    @discardableResult
    override func refreshAssets() -> Future<[PhotoAssetDescriptor], PhotoProviderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(PhotoProviderError.unknown))
                return
            }

            do {
                try self.startFolderAccess()
                defer {
                    self.stopFolderAccess()
                }

                self.photoURLs = try self.updatePhotoList() // setting photoURLs will also update photoDescriptors
                self.error = .none
            } catch let error as PhotoProviderError {
                self.error = error
            } catch {
                self.error = .unknown
            }

            if self.error != .none {
                promise(.failure(self.error))
            } else {
                promise(.success(self.photoDescriptors))
            }
        }
    }
}

struct LocalPhotoAsset: PhotoAssetDescriptor {
    var photoURL: URL
    var description: String { photoURL.path }

    var location: CLLocation? {
        // TODO: implement this
        return nil
    }
    var creationDate: Date? {
        // TODO: implement this
        return nil
    }

    func fetchImage(using provider: PhotoProvider) -> Future<NSImage, PhotoProviderError> {
        let photoURL = self.photoURL

        return Future { promise in
            guard let provider = provider as? LocalFolderPhotoProvider else {
                log.error("Invalid provider for \(self)")
                promise(.failure(.unknown))
                return
            }

            try? provider.startFolderAccess()
            defer {
                provider.stopFolderAccess()
            }

            guard let image = NSImage(contentsOf: photoURL) else {
                log.error("Failed to read file \(photoURL.path)")
                promise(.failure(.failedReadLocalFile))
                return
            }

            promise(.success(image))
        }
    }
}

enum LocalFolderProviderError: Error {
    case bookmarkFailure
    case accessFailure
}
