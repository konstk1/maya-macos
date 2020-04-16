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
            google.setActiveAlbum(album: google.albums[albumSelection])
        }
    }
    
    @Published var albumTitles: [String] = []
    
    var google: GooglePhotoProvider
    
    private var subs: Set<AnyCancellable> = []
    
    init(google: GooglePhotoProvider) {
        self.google = google
        self.google.albumsPublisher.sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                log.error("Error list google albums \(error.localizedDescription)")
            }
        }) { [weak self] albumList in
            self?.albumTitles = albumList.map { $0.title }
        }.store(in: &subs)
        
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
        }) { _ in /* nothing to do here */ }.store(in: &subs)
    }
}
