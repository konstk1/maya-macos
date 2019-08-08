//
//  PhotoVendor.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

protocol PhotoVendorDelegate: class {
    func didVendNewImage(image: NSImage)
    func didFailToVend(error: Error?)
}

final class PhotoVendor {
    /// Whether to show photos in random order. Defaults to `true`.
    var shufflePhotos: Bool = true {
        didSet {
            resetVendingState()
        }
    }
    
    weak var delegate: PhotoVendorDelegate?
    
    private var photoProvider: PhotoProvider?
    private var photos: [PhotoAssetDescriptor] = []
    
    init() {
        
    }
    
    /// Set new provider of photos.
    func setProvider(_ provider: PhotoProvider) {
        photoProvider = provider
        resetVendingState()
    }
    
    /// Clear all vending state, including shown photos, etc.
    func resetVendingState() {
        guard let photoProvider = photoProvider else {
            photos.removeAll()
            return
        }
        
        photos = photoProvider.photoDescriptors
        
        if shufflePhotos {
            photos.shuffle()
        }
    }
    
    /// Fetches next image and calls the delegate to notify when next image is ready
    func vendImage() {
        // if reached end of photos, reset the vending state (reload the list)
        if photos.isEmpty {
            resetVendingState()
        }
        
        // at this point, list shouldn't be empty, if it is, just return
        guard !photos.isEmpty else {
            log.warning("Photo vendor doesn't have any photos")
            return
        }
        
        let nextPhoto = photos.removeFirst()
        
        nextPhoto.fetchImage { [weak self] (result) in
            switch result {
            case .success(let image):
                self?.delegate?.didVendNewImage(image: image)
            case .failure(let error):
                log.error("Error converting descriptor to image (error: \(error.localizedDescription))")
                self?.delegate?.didFailToVend(error: error)
            }
        }
        
        refreshAssets()
    }
    
    func refreshAssets() {
        guard let photoProvider = photoProvider else { return }
        
        photoProvider.refreshAssets { (result) in
            switch result {
            case .success(let assets):
                // TODO: implement this
                fatalError("Not implemented")
            case .failure(let error):
                log.error("Error refreshing assets \(error.localizedDescription)")
            }
        }
    }
}
