//
//  GooglePhotosViewController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/28/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa

class GooglePhotosViewController: NSViewController {
    let google = GooglePhotoProvider()

    @IBOutlet weak var albumDropdown: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        log.verbose("GooglePhotosViewController loaded")

//        google.listAlbums { [weak self] (result) in
//            self?.refreshAlbumDropdown()
//        }
    }

    func refreshAlbumDropdown() {
        let menu = NSMenu()

        if !google.albums.isEmpty {
            for album in google.albums {
                let item = NSMenuItem(title: album.title, action: nil, keyEquivalent: "")
                menu.addItem(item)
            }
        } else {
            menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        }

        albumDropdown.menu = menu

        if let selectedIndex = google.albums.firstIndex(where: { $0.id == Settings.googlePhotos.activeAlbumId }) {
            albumDropdown.selectItem(at: selectedIndex)
        }
    }

    @IBAction func albumDropdownChanged(_ sender: NSPopUpButton) {
        let title = sender.titleOfSelectedItem

        guard let selectedAlbum = google.albums.first(where: { $0.title == title }) else {
            log.error("Selected title doesn't exist in Google albums")
            return
        }

        google.setActiveAlbum(album: selectedAlbum)
    }

    @IBAction func authorizedClicked(_ sender: NSButton) {
        print("Google Auth")
        _ = google.authorize().sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
//                self?.google.listAlbums()
                break
            case .failure(let error):
                log.error("Failed Google Auth: \(error)")
            }
        }, receiveValue: { _ in /* nothing to do here */ })
    }
}
