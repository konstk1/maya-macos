//
//  iCloudPhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import Combine
import Photos

final class iCloudPhotoProvider {
    let id = UUID()
    var photoCountPublisher = CurrentValueSubject<Int, Never>(0)
    var photoDescriptorsPublisher = CurrentValueSubject<[PhotoAssetDescriptor], Error>([])
    
    init() {
        
    }
}

extension iCloudPhotoProvider: PhotoProvider {
    var photoDescriptors: [PhotoAssetDescriptor] {
        log.warning("iCloud not implemented")
        return []
    }
    
    func refreshAssets() -> Future<[PhotoAssetDescriptor], Error> {
        fatalError("iCloud not implemented")
    }
}
