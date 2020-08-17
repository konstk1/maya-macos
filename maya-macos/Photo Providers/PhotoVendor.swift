//
//  PhotoVendor.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine

//protocol PhotoVendorDelegate: class {
//    func didVendNewImage(image: NSImage)
//    func didFailToVend(error: Error?)
//}

enum PhotoVendorError: Error {
    case noActiveProvider
    case noPhotos
    case trialExpired
    case providerError(error: PhotoProviderError)

    var localizedDescription: String {
        switch self {
        case .noActiveProvider: return "No active provider"
        case .noPhotos: return "No photos in active album"
        case .trialExpired: return "Trial expired"
        case .providerError(let providerError): return "Provider error \(providerError.localizedDescription)"
        }
    }
}

final class PhotoVendor: ObservableObject {
    static let shared = PhotoVendor()

    @Published var currentImage: NSImage?
    @Published var error: Error?

    /// Whether to show photos in random order. Defaults to `true`.
    var shufflePhotos: Bool = true {
        didSet {
            resetVendingState()
        }
    }

    var vendImageSub: AnyCancellable?
    var refreshAssetsSub: AnyCancellable?

    @Published private(set) var activeProvider: PhotoProvider?
    var photoProviders: [PhotoProvider] = []

    var activeProviderIndex: Int? {
        guard let activeProvider = activeProvider else { return nil }
        return photoProviders.firstIndex(of: activeProvider)
    }

    private var unshownPhotos: [PhotoAssetDescriptor] = []
    private var shownPhotos: [PhotoAssetDescriptor] = []

    private init() {
    }

    func add(provider: PhotoProvider) {
        photoProviders.append(provider)
        provider.refreshAssets()
    }

    /// Set new provider of photos.
    func setActiveProvider(_ provider: PhotoProvider) {
        activeProvider = provider                                       // update to new provider

        refreshAssets(shouldVend: true)     // since changing providers, vend new image after refreshing assets

        // TODO: how to handle errors

        Settings.app.activeProvider = provider.type                     // save to settings
    }

    func loadActiveProviderFromSettings() {
        if let activeProvider = photoProviders.first(where: { $0.type == Settings.app.activeProvider }) {
            setActiveProvider(activeProvider)
        } else {
            setActiveProvider(photoProviders[0])
        }
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

    /// Fetches next image
    /// - Parameter shouldRefresh: whether to refresh assets (rescan album)
    /// - Returns: Future that resolves to NSImage on success or Error on failure
    @discardableResult
    func vendImage(shouldRefresh: Bool) -> Future<NSImage, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            guard let activeProvider = self.activeProvider else {
                log.warning("No active photo provider")
                self.error = PhotoVendorError.noActiveProvider
                promise(.failure(PhotoVendorError.noActiveProvider))
                return
            }

            guard self.isProviderUnlocked(provider: activeProvider) else {
                log.warning("Provider is not unlocked")
                self.error = PhotoVendorError.trialExpired
                promise(.failure(PhotoVendorError.trialExpired))
                return
            }

            // if reached end of photos, reset the vending state (reload the list)
            if self.unshownPhotos.isEmpty {
                self.resetVendingState()
            }

            // at this point, list shouldn't be empty, if it is, just return
            guard !self.unshownPhotos.isEmpty else {
                log.warning("Photo vendor doesn't have any photos")
                self.error = PhotoVendorError.noPhotos
                promise(.failure(PhotoVendorError.noPhotos))
                return
            }

            // pop from unshown and add to shown
            let nextPhoto = self.unshownPhotos.removeFirst()
            self.shownPhotos.append(nextPhoto)

            self.vendImageSub = nextPhoto.fetchImage(using: activeProvider).receive(on: RunLoop.main).sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    log.error("Error converting descriptor to image (error: \(error.localizedDescription))")
                    self.error = error
                    promise(.failure(error))
                }
            }, receiveValue: { image in
                self.currentImage = image
                self.error = nil
                promise(.success(image))
            })

            // TODO: how often to refresh assets? (especially for remote providers)
            if shouldRefresh {
                self.refreshAssets()
            }
        }
    }

    func refreshAssets(shouldVend: Bool = false) {
        guard let activeProvider = activeProvider else { return }

        // overwriting subscription, will destroy previous sub and hook up new one
        refreshAssetsSub = activeProvider.refreshAssets().sink(receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
                log.error("Error refreshing assets: \(error.localizedDescription)")
                self?.error = error
            }
        }, receiveValue: { [weak self] assets in
            guard let self = self else { return }
            self.processNewAssetList(assets)
            if shouldVend {
                self.vendImage(shouldRefresh: false)
            }
        })
    }

    /// Merge new asset list with current assets.  Preserve shown assets and re-shuffle old un-shown and new assets.
    private func processNewAssetList(_ assets: [PhotoAssetDescriptor]) {
        // just need to filter OUT any assets that have been shown
        // everything else is going to become unshown
        unshownPhotos = assets.filter { asset in
            !shownPhotos.contains { photo in photo.description == asset.description }
        }

        if shufflePhotos {
            unshownPhotos.shuffle()
        }
    }

    private func isProviderUnlocked(provider: PhotoProvider) -> Bool {
        StoreManager.shared.refreshAllSourcesStatus()

        switch provider {
        case is LocalFolderPhotoProvider:
            return true     // local folder always unlocked
        case is ApplePhotoProvider:
            return true     // can't charge for apple photos as per apple guidelines
        default:
            log.error("Unexpected PhotoProvider: \(provider)")
            return false
        }
    }
}
