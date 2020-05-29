//
//  LocalFolderSourceViewModel.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/17/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine

class LocalFolderViewModel: ObservableObject {
    @Published var folderSelection: Int = 0 {
        didSet {
            if folderSelection == 0 {
                return
            }
            print("Selected \(folderSelection)")
            if folderSelection < settings.recentFolders.count {
                // this will refresh assets so vend doesn't need to refresh
                updateFolderSelection(url: settings.recentFolders[folderSelection])
                // only vend if this is active provider
                if PhotoVendor.shared.activeProvider == localPhotoProvider {
                    PhotoVendor.shared.refreshAssets(shouldVend: true)
                }
            } else if folderSelection == 5 {
                chooseFolder()
            }
            folderSelection = 0
        }
    }

    @Published var recentFolders: [String] = []
    @Published var photoCount = 0
    @Published var isActive: Bool

    private var settings = Settings.localFolderProvider

    private var localPhotoProvider: LocalFolderPhotoProvider

    private var subs: Set<AnyCancellable> = []

    init(provider: LocalFolderPhotoProvider) {
        log.warning("Init LocalFolderSourceViewModel")
        localPhotoProvider = provider
        isActive = (PhotoVendor.shared.activeProvider == provider)

        settings.$recentFolders.sink { [weak self] (recents) in
            print("Updating recent folders")
            self?.recentFolders = recents.map { $0.path }
        }.store(in: &subs)

        NotificationCenter.default.publisher(for: .updatePhotoCount, object: localPhotoProvider).receive(on: RunLoop.main).sink { [weak self] in
            guard let self = self else { return }
            self.photoCount = $0.userInfo?["photoCount"] as? Int ?? 0
            print("Updated photo count: \(self.photoCount)")
        }.store(in: &subs)
    }

    deinit {
        log.warning("LocalFolderViewModel deinit")
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        panel.begin { [weak self] (response) in
            guard let self = self else { log.error("self doesn't exist anymore"); return }

            if response == .OK {
                if let selectedUrl = panel.url {
                    self.updateFolderSelection(url: selectedUrl)
                }
            } else {
                // cancel clicked, restore previously selected item (first item in the list)
                self.folderSelection = 0
            }
        }
    }

    private func updateFolderSelection(url: URL) {
        do {
            try localPhotoProvider.setActiveFolder(url: url)
        } catch {
            log.error("Failed to set active url \(error)")
        }
    }

    func activateClicked() {
        log.info("Activating Apple Photos")
        PhotoVendor.shared.setActiveProvider(localPhotoProvider)
        isActive = true
    }
}
