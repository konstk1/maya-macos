//
//  AppleSourceViewModel.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 3/17/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation
import Combine
import Photos

class AppleSourceViewModel: ObservableObject {
    @Published var albumSelection: Int {
        didSet {
            print("Album sel \(albumSelection)")
            apple.setActiveAlbum(album: apple.albums[albumSelection])
            // only vend if this is active provider
            if PhotoVendor.shared.activeProvider == apple {
                PhotoVendor.shared.refreshAssets(shouldVend: true)
            }
        }
    }

    @Published private(set) var albumTitles: [String] = []

    @Published var isActive: Bool

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var isPurchased: Bool = false
    @Published private(set) var isTrialAvailable: Bool = false
    @Published private(set) var trialDaysLeft: Int = -1
    @Published private(set) var unlockPrice: String
    @Published var isIapError: Bool = false

    private var apple: ApplePhotoProvider
    private var store = StoreManager.shared

    private var subs: Set<AnyCancellable> = []

    init(apple: ApplePhotoProvider) {
        self.apple = apple

        isActive = (PhotoVendor.shared.activeProvider == apple)
        isAuthorized = (apple.authStatus == .authorized)

        if let selectedIndex = apple.albums.firstIndex(where: { $0.localIdentifier == Settings.applePhotos.activeAlbumId }) {
            albumSelection = selectedIndex
        } else {
            albumSelection = 0
        }

        unlockPrice = store.getApplePhotosPrice() ?? ""

        self.apple.albumsPublisher.sink { [weak self] albums in
            guard let self = self else { return }
            self.albumTitles = albums.map { $0.localizedTitle ?? "Untitled" }
        }.store(in: &subs)

        self.apple.$authStatus.removeDuplicates().receive(on: RunLoop.main).sink { [weak self] status in
            guard let self = self else { return }
            log.info("Apple auth status \(status.rawValue)")
            if status == .authorized {
                self.isAuthorized = true
                self.apple.listAlbums()
            } else {
                self.isAuthorized = false
            }
        }.store(in: &subs)

        let processStoreStatus: (StoreManager.UnlockStatus) -> Void = { [weak self] unlockStatus in
            guard let self = self else { return }
            switch unlockStatus {
            case .locked:
                self.isTrialAvailable = true
                self.isPurchased = false
                self.trialDaysLeft = -1
            case .freeTrial(let daysRemaining):
                self.isTrialAvailable = false
                self.isPurchased = true
                self.trialDaysLeft = daysRemaining
            case .freeTrialExpired:
                self.isTrialAvailable = false
                self.isPurchased = false
                self.trialDaysLeft = -1
            case .purchased:
                self.isTrialAvailable = false
                self.isPurchased = true
                self.trialDaysLeft = -1
            }
        }

        // process apple photos store status immediately and also subscribe to notifications
        // otherwise the publishes take just long enough to notice the change
        processStoreStatus(store.applePhotosSourceStatus)
        store.$applePhotosSourceStatus.receive(on: RunLoop.main).sink(receiveValue: processStoreStatus).store(in: &subs)

        store.eventPublisher.receive(on: RunLoop.main).sink { [weak self] event in
            guard let self = self else { return }
            // on failure, set iap error flag (it will be reset when alert is dismissed)
            // on success, just refresh anything IAP related
            switch event {
            case .failure:
                self.isIapError = true
            default:
                self.unlockPrice = self.store.getApplePhotosPrice() ?? ""
            }
            self.isPurchasing = false
        }.store(in: &subs)

        store.refreshAllSourcesStatus()

        self.apple.authorize()
    }

    deinit {
        log.warning("AppleSourceViewModel deinit")
    }

    func updateAlbums(albumList: [PHAssetCollection]) {
        albumTitles = albumList.map { $0.localizedTitle ?? "Untitled" }

        print("Album sel after list \(albumSelection)")
    }

    func activateClicked() {
        log.info("Activating Apple Photos")
        if isAuthorized {
            PhotoVendor.shared.setActiveProvider(apple)
            isActive = true
        }
    }

    func authorizeClicked() {
        print("Apple Auth")
        apple.authorize()
    }

    func purchaseTrial() {
        isPurchasing = true
        store.buyApplePhotosTrial()
    }

    func purchaseFull() {
        isPurchasing = true
        store.buyApplePhotosFull()
    }

    func refreshIaps() {
        store.refreshProducts()
    }
}
