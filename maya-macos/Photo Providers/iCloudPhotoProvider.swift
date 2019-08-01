//
//  iCloudPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import Photos

final class iCloudPhotoProvider {
    
    init() {
        
    }
}

extension iCloudPhotoProvider: PhotoProvider {
    var photoDescriptors: [PhotoAssetDescriptor] {
        return []
    }
}
