//
//  LocalFolderPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

final class LocalFolderPhotoProvider {
    /// Whether or not to look into sub-folders while looking for photos
    var descendIntoSubfolders = false   // TODO: implement this
    
    /// Supported photo file extensions
    private let supportedExtension = ["png", "jpg", "jpeg"]
    
    private let fileManager = FileManager.default
    
    private var folder: URL? {
        didSet {
            do {
                log.info("Setting folder URL: \(folder?.path ?? "nil")")
                photoURLs = try updatePhotoList()
                // save folder bookmark to user defaults
                let bookmark = try folder?.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
                UserDefaults.standard.set(bookmark, forKey: "bookmark")
            } catch {
                log.error("Failed to read folder/save bookmark: \(error)")
            }
        }
    }
    
    private var photoURLs: [URL] = [] {
        didSet {
            // reset current photo index if new list assigned
            currentPhotoIndex = 0
        }
    }
    private var currentPhotoIndex = 0
    
    init() {
//        UserDefaults.standard.removeObject(forKey: "bookmark")
        if let bookmarkData = UserDefaults.standard.object(forKey: "bookmark") as? Data {
            do {
                var isStale: Bool = false
                var selectedFolder: URL? = try URL(resolvingBookmarkData: bookmarkData, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                // use defer here to trigger didSet on folder property
                defer {
                    folder = selectedFolder
                }
                
                if selectedFolder?.startAccessingSecurityScopedResource() != true {
                    print("Failed to access security resource")
                    selectedFolder = nil // reset folder to nil to indicate it's not accessible
                }
                
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        } else {
            chooseFolder()
        }
        log.info("Init done")
    }
    
    deinit {
        folder?.stopAccessingSecurityScopedResource()
    }
    
    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        panel.begin { [weak self] (response) in
            guard let strongSelf = self else { print("Warning: self doesn't exist anymore"); return }
            
            if response == .OK {
                if let selectedUrl = panel.url {
                    print("Selected \(selectedUrl)")
                    strongSelf.folder = selectedUrl
                }
            } else {
                print("Panel \(response.rawValue)")
            }
        }
    }
    
    func updatePhotoList() throws -> [URL] {
        guard let folder = folder else { return [] }
            
        let urls = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
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

