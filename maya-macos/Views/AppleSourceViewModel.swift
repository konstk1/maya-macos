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
    @Published var albumSelection: Int = 0 {
        didSet {
            print("Album sel \(albumSelection)")
            apple.setActiveAlbum(album: apple.albums[albumSelection])
            PhotoVendor.shared.refreshAssets(shouldVend: true)
        }
    }
    
    @Published private(set) var albumTitles: [String] = []

    @Published private(set) var isAuthorized: Bool = false

    private var apple: ApplePhotoProvider
    
    private var subs: Set<AnyCancellable> = []
    
    init(apple: ApplePhotoProvider) {
        self.apple = apple

        self.apple.albumsPublisher
            .map { $0.map { $0.localizedTitle ?? "Untitled" } }
            .assign(to: \.albumTitles, on: self).store(in: &subs)

        self.apple.$authStatus.receive(on: RunLoop.main).sink { status in
            log.info("Apple auth status \(status.rawValue)")
            if status == .authorized {
                self.isAuthorized = true
                self.apple.listAlbums()
            } else {
                self.isAuthorized = false
            }
        }
    }

    func updateAlbums(albumList: [PHAssetCollection]) {
        albumTitles = albumList.map { $0.localizedTitle ?? "Untitled" }
        //            if let selectedIndex = google.albums.firstIndex(where: { $0.id == Settings.googlePhotos.activeAlbumId }) {
        //                self?.albumSelection = selectedIndex
        //            }
        print("Album sel after list \(albumSelection)")
    }
    
    func authorizeClicked() {
        print("Apple Auth")
        apple.authorize()
    }
}
