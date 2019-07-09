//
//  LocalFolderPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

final class LocalFolderPhotoProvider {
    
    private let fileManager = FileManager.default
    
    private var folder: URL? {
        didSet {
            do {
                let bookmark = try folder?.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
                UserDefaults.standard.set(bookmark, forKey: "bookmark")
            } catch {
                print("Failed to save bookmark: \(error)")
            }
        }
    }
    
    init() {
        if let bookmarkData = UserDefaults.standard.object(forKey: "bookmark") as? Data {
            do {
                var isStale: Bool = false
                folder = try URL(resolvingBookmarkData: bookmarkData, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                if folder?.startAccessingSecurityScopedResource() != true {
                    print("Failed to access security resource")
                    folder = nil // reset folder to nil to indicate it's not accessible
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        } else {
            chooseFolder()
        }
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
}

extension LocalFolderPhotoProvider: PhotoProvider {
    func nextImage() -> NSImage {
        return NSImage()
    }
}
