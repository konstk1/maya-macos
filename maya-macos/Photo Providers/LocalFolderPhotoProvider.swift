//
//  LocalFolderPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

final class LocalFolderPhotoProvider {
    /// supported photo file extensions
    private let supportedExtension = ["png", "jpg", "jpeg"]
    
    private let fileManager = FileManager.default
    
    private var folder: URL? {
        didSet {
            do {
                log.info("Setting folder URL: \(folder?.path ?? "nil")")
                updatePhotoList()
                // save folder bookmark to user defaults
                let bookmark = try folder?.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
                UserDefaults.standard.set(bookmark, forKey: "bookmark")
            } catch {
                log.error("Failed to save bookmark: \(error)")
            }
        }
    }
    
    private var photoUrls: [URL] = [] {
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
    
    func updatePhotoList() {
        guard let folder = folder else { return }
        do {
            let urls = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
            photoUrls = urls.filter { supportedExtension.contains($0.pathExtension) }.shuffled()
        } catch {
            print("Failed to get contents of \(folder.absoluteString): \(error)")
        }
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
        return photoUrls.map { LocalPhotoAsset(photoURL: $0) }
    }
}
