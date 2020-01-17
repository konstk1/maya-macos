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
    weak var delegate: PhotoProviderDelegate?
    
    lazy var photoCountPublisher = CurrentValueSubject<Int, Never>(0)
    
    init() {
        
    }
}

extension iCloudPhotoProvider: PhotoProvider {
    var photoDescriptors: [PhotoAssetDescriptor] {
        log.warning("iCloud not implemented")
        return []
    }
    
    func refreshAssets(completion: @escaping (Result<[PhotoAssetDescriptor], Error>) -> Void) {
        log.warning("iCloud not implemented")
        completion(.success([]))
    }
}
