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

    func fetchImage(using provider: PhotoProvider) -> Future<NSImage, PhotoProviderError> {
        guard let provider = provider as? GooglePhotoProvider else {
            log.error("Invalid provider for \(self)")
            return Future { $0(.failure(PhotoProviderError.unknown)) }
        }

        return provider.getPhoto(id: photoId)
    }
}
