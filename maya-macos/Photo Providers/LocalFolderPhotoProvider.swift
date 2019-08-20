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
    private var photoURLs: [URL] = []
    
    /// Supported photo file extensions
    private let supportedExtension = ["png", "jpg", "jpeg"]
    
    private let fileManager = FileManager.default
    
    private var activeFolder: URL? {
        didSet {
           
        }
    }
    
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
        activeFolder?.stopAccessingSecurityScopedResource()
    }
    
    func setActiveFolder(url: URL) throws {
        //  previous folder
        let previousFolder = activeFolder

        log.info("Setting folder URL: \(url.path)")
        
        // check if url has bookmark data
        if let bookmarkData = try? url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess]) {
            Settings.localFolderProvider.bookmarks[url] = bookmarkData
            activeFolder = url
        } else {
            // load bookmark from settings
            activeFolder = try loadBookmark(for: url)
        }
        
        // if everything was successful, stop access to previous folder, unless previous and active folder are the same
        if previousFolder != activeFolder {
            previousFolder?.stopAccessingSecurityScopedResource()
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
        let secScopedUrl = try URL(resolvingBookmarkData: bookmarkData, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
        
        guard secScopedUrl.startAccessingSecurityScopedResource() else {
            log.error("Failed to access security resource of \(url.path)")
            throw LocalFolderProviderError.bookmarkFailure
        }
        
        return secScopedUrl
    }
    
    private func saveBookmark(for url: URL) {
        do {
            Settings.localFolderProvider.bookmarks[url] = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
        } catch {
            log.error("Failed to save bookmark for \(url.path)")
        }
    }
    
    private func updateRecents(with url: URL) {
        let maxRecentFolders = 3
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
        guard let activeFolder = activeFolder else { return [] }
            
        let urls = try fileManager.contentsOfDirectory(at: activeFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
        return urls.filter { supportedExtension.contains($0.pathExtension) }
    }
}

struct LocalPhotoAsset: PhotoAssetDescriptor {
    var photoURL: URL
    var description: String { photoURL.path }
    
    func fetchImage(completion: (Result<NSImage, Error>) -> Void) {
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
        let result = Result { try updatePhotoList() }.map {
            // convert LocalPhotoAsset to PhotoAssetDescriptor
            $0.map { LocalPhotoAsset(photoURL: $0) as PhotoAssetDescriptor }
        }
        completion(result)
    }
}

enum LocalFolderProviderError: Error {
    case bookmarkFailure
}
