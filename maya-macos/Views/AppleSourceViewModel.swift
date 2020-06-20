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

    private var apple: ApplePhotoProvider

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
}
