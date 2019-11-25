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

enum PhotoVendorError: Error {
    case noActiveProvider
}

final class PhotoVendor: PhotoProviderDelegate {
    static let shared = PhotoVendor()
    
    /// Whether to show photos in random order. Defaults to `true`.
    var shufflePhotos: Bool = true {
        didSet {
            resetVendingState()
        }
    }
    
    weak var delegate: PhotoVendorDelegate?
    
    private(set) var activeProvider: PhotoProvider?
    var photoProviders: [PhotoProvider] = []
    
    private var unshownPhotos: [PhotoAssetDescriptor] = []
    private var shownPhotos: [PhotoAssetDescriptor] = []
    
    private init() {
    }
    
    func add(provider: PhotoProvider) {
        photoProviders.append(provider)
    }
    
    /// Set new provider of photos.
    func setActiveProvider(_ provider: PhotoProvider) {
        activeProvider?.delegate = nil   // disconnect previous active provider
        activeProvider = provider        // update to new provider
        activeProvider?.delegate = self  // connect new delegate
        
        activeProvider?.refreshAssets(completion: { [weak self] result in
            self?.resetVendingState()
            self?.vendImage()
        })
        
    }
    
    /// PhotoProviderDelegate method
    func didUpdateAssets(assets: [PhotoAssetDescriptor] ) {
        processNewAssetList(assets)
        vendImage()
    }
    
    /// Clear all vending state, including shown photos, etc.
    func resetVendingState() {
        guard let activeProvider = activeProvider else {
            unshownPhotos.removeAll()
            shownPhotos.removeAll()
            return
        }
        
        unshownPhotos = activeProvider.photoDescriptors
        
        if shufflePhotos {
            unshownPhotos.shuffle()
        }
    }
    
    /// Fetches next image and calls the delegate to notify when next image is ready
    func vendImage() {
        guard activeProvider != nil else {
            log.warning("No active photo provider")
            delegate?.didFailToVend(error: PhotoVendorError.noActiveProvider)
            return
        }
        
        // if reached end of photos, reset the vending state (reload the list)
        if unshownPhotos.isEmpty {
            resetVendingState()
        }
        
        // at this point, list shouldn't be empty, if it is, just return
        guard !unshownPhotos.isEmpty else {
            log.warning("Photo vendor doesn't have any photos")
            delegate?.didFailToVend(error: nil)
            return
        }
        
        // pop from unshown and add to shown
        let nextPhoto = unshownPhotos.removeFirst()
        shownPhotos.append(nextPhoto)
        
        nextPhoto.fetchImage { [weak self] (result) in
            switch result {
            case .success(let image):
                self?.delegate?.didVendNewImage(image: image)
            case .failure(let error):
                log.error("Error converting descriptor to image (error: \(error.localizedDescription))")
                self?.delegate?.didFailToVend(error: error)
            }
        }
        
        // TODO: how often to refresh assets? (especially for remote providers)
        refreshAssets()
    }
    
    func refreshAssets() {
        guard let activeProvider = activeProvider else { return }
        
        activeProvider.refreshAssets { [weak self] (result) in
            switch result {
            case .success(let assets):
                self?.processNewAssetList(assets)
            case .failure(let error):
                log.error("Error refreshing assets \(error.localizedDescription)")
            }
        }
    }
    
    /// Merge new asset list with current assets.  Preserve shown assets and re-shuffle old un-shown and new assets.
    func processNewAssetList(_ assets: [PhotoAssetDescriptor]) {
        // just need to filter OUT any assets that have been shown
        // everything else is going to become unshown
        unshownPhotos = assets.filter { asset in
            !shownPhotos.contains { photo in
                photo.description == asset.description
            }
        }
        
        if shufflePhotos {
            unshownPhotos.shuffle()
        }
    }
}
