//
//  LocalFolderPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

final class LocalFolderPhotoProvider {
    static let shared = LocalFolderPhotoProvider()
    
    weak var delegate: PhotoProviderDelegate?
    
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
        }
    }
    
    /// Supported photo file extensions
    private let supportedExtension = ["png", "jpg", "jpeg"]
    
    private let fileManager = FileManager.default
    
    private var activeFolder: URL = URL(fileURLWithPath: "")
    
    private init() {
        guard let lastActiveFolder = Settings.localFolderProvider.recentFolders.first else { return }
        
        do {
            activeFolder = try loadBookmark(for: lastActiveFolder)
            photoURLs = try updatePhotoList()
        } catch {
            print("Failed initialize Local Folder provider: \(error)")
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
        
        // notify delegate that assets were updated
        delegate?.didUpdateAssets()
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
        guard activeFolder.startAccessingSecurityScopedResource() else {
            log.error("Failed to access security resource of \(activeFolder.path)")
            throw LocalFolderProviderError.accessFailure
        }
    }
    
    func stopFolderAccess() {
        activeFolder.stopAccessingSecurityScopedResource()
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
        recents.removeAll{ $0 == url}
        recents.insert(url, at: 0)
        if recents.count > maxRecentFolders {
            recents.removeSubrange(maxRecentFolders...)
        }
        
        Settings.localFolderProvider.recentFolders = recents
    }
    
    func updatePhotoList() throws -> [URL] {
        try startFolderAccess()
        defer {
            stopFolderAccess()
        }
        let urls = try fileManager.contentsOfDirectory(at: activeFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
        return urls.filter { supportedExtension.contains($0.pathExtension) }
    }
}

struct LocalPhotoAsset: PhotoAssetDescriptor {
    var photoURL: URL
    var description: String { photoURL.path }
    
    func fetchImage(completion: (Result<NSImage, Error>) -> Void) {
        try? LocalFolderPhotoProvider.shared.startFolderAccess()
        defer {
            LocalFolderPhotoProvider.shared.stopFolderAccess()
        }
        guard let image = NSImage(contentsOf: photoURL) else {
            log.error("Failed to read file \(photoURL.path)")
            completion(.failure(PhotoProviderError.failedReadLocalFile))
            return
        }
        
        completion(.success(image))
    }
}

extension LocalFolderPhotoProvider: PhotoProvider {
    var photoDescriptors: [PhotoAssetDescriptor] {
        return photoURLs.map { LocalPhotoAsset(photoURL: $0) }
    }
    
    func refreshAssets(completion: @escaping (Result<[PhotoAssetDescriptor], Error>) -> Void) {
        try? startFolderAccess()
        defer {
            stopFolderAccess()
        }
        let result = Result { try updatePhotoList() }.map {
            // convert LocalPhotoAsset to PhotoAssetDescriptor
            $0.map { LocalPhotoAsset(photoURL: $0) as PhotoAssetDescriptor }
        }
        completion(result)
    }
}

enum LocalFolderProviderError: Error {
    case bookmarkFailure
    case accessFailure
}

