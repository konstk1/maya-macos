//
//  PhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/1/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

protocol PhotoProvider {
    var photoDescriptors: [PhotoAssetDescriptor] { get }
}

protocol PhotoAssetDescriptor: CustomStringConvertible {
    // fetches an image for underlying photo asset
    func fetchImage(completion: (Result<NSImage, Error>) -> Void)
}

enum PhotoProviderError: Error {
    case failedReadLocalFile
}
