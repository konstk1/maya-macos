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

final class iCloudPhotoProvider: PhotoProvider {

    @discardableResult
    override func refreshAssets() -> Future<[PhotoAssetDescriptor], PhotoProviderError> {
        fatalError("iCloud not implemented")
    }
}

