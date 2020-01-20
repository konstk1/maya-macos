//
//  GooglePhotoAsset.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import Combine

struct GooglePhotoAsset: PhotoAssetDescriptor {
    
    var photoId: String
    var description: String { "/* TODO: Implement this */" }
    
    func fetchImage() -> Future<NSImage, Error> {
        fatalError("Not implemented")
//        GooglePhotoProvider.shared.getPhoto(id: photoId, completion: completion)
    }
}
