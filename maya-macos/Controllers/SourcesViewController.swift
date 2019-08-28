//
//  SourcesViewController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/11/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

enum ProviderTypes: String {
    case localFolder = "Local Folder"
    case googlePhotos = "Google Photos"
}

class SourcesViewController: NSViewController {
    lazy var sources = [
        (name: ProviderTypes.localFolder, image: NSImage(named: NSImage.folderName), isActive: false),
        (name: ProviderTypes.googlePhotos, image: NSImage(named: NSImage.everyoneName), isActive: false)
    ]
    
    @IBOutlet var localFolderVC: LocalFolderProviderViewController!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var sourceView: NSView!
    
    private var currentSourceController: NSViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let activeIndex = sources.firstIndex { $0.isActive == true } ?? 0
        selectViewControllerAt(index: activeIndex)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatePhotoCount(_:)), name: .updatePhotoCount, object: nil)
    }
    
    @objc func updatePhotoCount(_ notification: Notification) {
        log.debug("Update photo count notification \(String(describing: notification.object))")
        // reload all cells which will query the new photo counts
        tableView.reloadData()
    }
    
    func selectViewControllerAt(index: Int) {
        // remove current view controller, if any
        if let currentSourceController = currentSourceController {
            currentSourceController.removeFromParent()
        }
        
        let source = sources[index].name
        
        // add new view controller
        switch source {
        case .localFolder:
            // load local folder controller
            currentSourceController = localFolderVC
        case.googlePhotos:
            // TODO: implement this, for now just return
            return
        }
        
        self.addChild(currentSourceController!)
        currentSourceController!.view.frame = NSRect(x: 0, y: 0, width: sourceView.frame.width, height: sourceView.frame.height)
        sourceView.addSubview(currentSourceController!.view)
    }
    
    @IBAction func activateClicked(_ sender: NSButton) {
        let row = tableView.row(for: sender)
        print("Active in row \(row)")
        
        for (idx, _) in sources.enumerated() {
            sources[idx].isActive = (row == idx)
        }
        
        tableView.reloadData()
    }
}

extension SourcesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sources.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SourceCell"), owner: nil) as? SourceCell else { return nil }
        
        cell.titleLabel.stringValue = sources[row].name.rawValue
        cell.iconView.image = sources[row].image
        
        var photoCount = 0
        if row == 0 {
            photoCount = LocalFolderPhotoProvider.shared.photoDescriptors.count
        }
        cell.photoCountLabel.title = String(photoCount)
        
        // configure activate radio button
        cell.activateButton.state = sources[row].isActive ? .on : .off
        cell.activateButton.action = #selector(activateClicked(_:))
        cell.activateButton.target = self
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView, tableView.selectedRow >= 0 else {
                return
        }
        
        selectViewControllerAt(index: tableView.selectedRow)
    }
}
