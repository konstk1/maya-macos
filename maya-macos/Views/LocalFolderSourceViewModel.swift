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
                updateFolderSelection(url: settings.recentFolders[folderSelection])
            } else if folderSelection == 5 {
                chooseFolder()
            }
            folderSelection = 0
        }
    }
    @Published var recentFolders: [String] = []
    @Published var photoCount = 0
    
    private var settings = Settings.localFolderProvider
    
    
    private lazy var localPhotoProvider = LocalFolderPhotoProvider.shared
    
    private var subs: Set<AnyCancellable> = []
    
    init() {
        settings.$recentFolders.sink { [weak self] (recents) in
            print("Updating recent folders")
            self?.recentFolders = recents.map { $0.path }
        }.store(in: &subs)
        
        NotificationCenter.default.publisher(for: .updatePhotoCount, object: localPhotoProvider).receive(on: RunLoop.main).sink { [weak self] in
            self?.photoCount = $0.userInfo?["photoCount"] as? Int ?? 0
            print("Updated photo count: \(self?.photoCount ?? -1)")
        }.store(in: &subs)
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
       
       @IBAction func chooseClicked(_ sender: NSButton) {
           chooseFolder()
       }
       
       @IBAction func folderSelectionDropdownChanged(_ sender: NSPopUpButton) {
           guard let path = sender.titleOfSelectedItem else {
               log.error("nil path in folder dropdown")
               return
           }
           
           let url = URL(fileURLWithPath: path, isDirectory: true)
           
           updateFolderSelection(url: url)
       }
}
