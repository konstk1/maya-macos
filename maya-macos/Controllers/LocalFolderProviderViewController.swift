//
//  LocalFolderProviderViewController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/20/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class LocalFolderProviderViewController: NSViewController {
    
    lazy var localPhotoProvider = LocalFolderPhotoProvider()

    @IBOutlet weak var folderSelectionDropdown: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        log.verbose("LocalFolderProviderViewController loaded")
        refreshFolderSelectionDropdown()
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
                self.folderSelectionDropdown.selectItem(at: 0)
            }
        }
    }
    
    private func updateFolderSelection(url: URL) {
        do {
            try localPhotoProvider.setActiveFolder(url: url)
            refreshFolderSelectionDropdown()
        } catch {
            log.error("Failed to set active url \(error)")
        }
    }
    
    func refreshFolderSelectionDropdown() {
        let menu = NSMenu()
        
        if localPhotoProvider.recentFolders.count > 0 {
            for folder in localPhotoProvider.recentFolders {
                let item = NSMenuItem(title: folder.path, action: nil, keyEquivalent: "")
                menu.addItem(item)
            }
        } else {
            menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        }
        
        menu.addItem(NSMenuItem.separator())
        let item = NSMenuItem(title: "Choose a new folder...", action: #selector(chooseClicked), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        
        folderSelectionDropdown.menu = menu
        folderSelectionDropdown.selectItem(at: 0)
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
