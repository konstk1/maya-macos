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
    func refreshAssets(completion: @escaping (Result<[PhotoAssetDescriptor], Error>) -> Void)
}

protocol PhotoAssetDescriptor: CustomStringConvertible {
    // fetches an image for underlying photo asset
    func fetchImage(completion: @escaping (Result<NSImage, Error>) -> Void)
}

enum PhotoProviderError: Error {
    case failedReadLocalFile
}
