//
//  LocalFolderPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

final class LocalFolderPhotoProvider {
    
}

extension LocalFolderPhotoProvider: PhotoProvider {
    func nextImage() -> NSImage {
        return NSImage()
    }
}
