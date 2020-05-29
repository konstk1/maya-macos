//
//  GoogleSourceViewModel.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 3/17/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation
import Combine

class GoogleSourceViewModel: ObservableObject {
    @Published var albumSelection: Int = 0 {
        didSet {
            print("Album sel \(albumSelection)")
            google.setActiveAlbum(album: google.albums[albumSelection]).sink(receiveCompletion: { completion in
                if case .finished = completion {
                    PhotoVendor.shared.refreshAssets(shouldVend: true)
                }
            }, receiveValue: { _ in }).store(in: &subs)
        }
    }

    @Published private(set) var albumTitles: [String] = []

    var google: GooglePhotoProvider

    private var subs: Set<AnyCancellable> = []

    init(google: GooglePhotoProvider) {
        self.google = google
        self.google.albumsPublisher.sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                log.error("Error list google albums \(error.localizedDescription)")
            }
        }, receiveValue: { [weak self] albumList in
            guard let self = self else { return }
            if self.albumTitles.isEmpty {
                self.albumTitles = albumList.map { $0.title }
            }
//            if let selectedIndex = google.albums.firstIndex(where: { $0.id == Settings.googlePhotos.activeAlbumId }) {
//                self?.albumSelection = selectedIndex
//            }
            print("Album sel after list \(self.albumSelection)")
        }).store(in: &subs)

        _ = self.google.listAlbums()
    }

    func authorizeClicked() {
        print("Google Auth")
        google.authorize().sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                self?.google.listAlbums()
            case .failure(let error):
                log.error("Failed Google Auth: \(error)")
            }
        }, receiveValue: { _ in /* nothing to do here */ }).store(in: &subs)
    }
}
