//
//  GooglePhotoAsset.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine
import CoreLocation

struct GooglePhotoAsset: PhotoAssetDescriptor {
    var photoId: String
    var description: String { "/* TODO: Implement this */" }

    var location: CLLocation? {
        // TODO: implement this
        return nil
    }

    var creationDate: Date? {
        // TODO: implement this
        return nil
    }

    func fetchImage(using provider: PhotoProvider) -> Future<NSImage, PhotoProviderError> {
        guard let provider = provider as? GooglePhotoProvider else {
            log.error("Invalid provider for \(self)")
            return Future { $0(.failure(PhotoProviderError.unknown)) }
        }

        return provider.getPhoto(id: photoId)
    }
}
