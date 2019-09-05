//
//  GooglePhotoAsset.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

struct GooglePhotoAsset: PhotoAssetDescriptor {
    var photoId: String
    var description: String { "/* TODO: Implement this */" }
    
    func fetchImage(completion: @escaping (Result<NSImage, Error>) -> Void) {
        GooglePhotoProvider.shared.getPhoto(id: photoId, completion: completion)
    }
}
