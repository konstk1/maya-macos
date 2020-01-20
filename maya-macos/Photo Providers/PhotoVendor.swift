//
//  PhotoVendor.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import Combine

protocol PhotoVendorDelegate: class {
    func didVendNewImage(image: NSImage)
    func didFailToVend(error: Error?)
}

enum PhotoVendorError: Error {
    case noActiveProvider
}

final class PhotoVendor: ObservableObject {
    static let shared = PhotoVendor()
    
    @Published var currentImage: NSImage?
    
    /// Whether to show photos in random order. Defaults to `true`.
    var shufflePhotos: Bool = true {
        didSet {
            resetVendingState()
        }
    }
    
    var vendImageSub: AnyCancellable?
    var refreshAssetsSub: AnyCancellable?
    
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
        activeProvider = provider        // update to new provider
        
        // overwriting subscription, will destroy previous sub and hook up new one
        refreshAssetsSub = activeProvider?.refreshAssets().sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                log.error("Error: \(error.localizedDescription)")
            }
        }, receiveValue: { [weak self] assets in
            guard let self = self else { return; }
            self.processNewAssetList(assets)
            self.vendImage()
        })
        
        // TODO: how to handle errors
        
        // save to settings
        Settings.app.activeProvider = provider.type
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
            fatalError("Not implemented")
//            delegate?.didFailToVend(error: PhotoVendorError.noActiveProvider)
            return
        }
        
        // if reached end of photos, reset the vending state (reload the list)
        if unshownPhotos.isEmpty {
            resetVendingState()
        }
        
        // at this point, list shouldn't be empty, if it is, just return
        guard !unshownPhotos.isEmpty else {
            log.warning("Photo vendor doesn't have any photos")
//            delegate?.didFailToVend(error: nil)
            fatalError("Not implemented")
            return
        }
        
        // pop from unshown and add to shown
        let nextPhoto = unshownPhotos.removeFirst()
        shownPhotos.append(nextPhoto)
        
        vendImageSub = nextPhoto.fetchImage().receive(on: RunLoop.main).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                log.error("Error converting descriptor to image (error: \(error.localizedDescription))")
                // TODO: notify delegate?
                // self?.delegate?.didFailToVend(error: error)
            }
        }) { [weak self] image in
            guard let self = self else { return }
            self.currentImage = image
        }
        
        // TODO: how often to refresh assets? (especially for remote providers)
        refreshAssets()
    }
    
    func refreshAssets() {
        guard let activeProvider = activeProvider else { return }
        
        refreshAssetsSub = activeProvider.refreshAssets().sink(receiveCompletion: { (completion) in
            if case .failure(let error) = completion {
                log.error("Error refreshing assets \(error.localizedDescription)")
            }
        }) { [weak self] (photoAssets) in
            guard let self = self else { return }
            self.processNewAssetList(photoAssets)
        }
    }
    
    /// Merge new asset list with current assets.  Preserve shown assets and re-shuffle old un-shown and new assets.
    func processNewAssetList(_ assets: [PhotoAssetDescriptor]) {
        // just need to filter OUT any assets that have been shown
        // everything else is going to become unshown
        unshownPhotos = assets.filter { asset in
            !shownPhotos.contains { photo in photo.description == asset.description }
        }
        
        if shufflePhotos {
            unshownPhotos.shuffle()
        }
    }
}
