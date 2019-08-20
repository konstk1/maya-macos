//
//  SourcesViewController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/11/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class SourcesViewController: NSViewController {
    lazy var sources = [
            (name: "Local Folder", image: NSImage(named: NSImage.folderName)),
            (name: "Google Photos", image: NSImage(named: NSImage.everyoneName))
    ]
    
    @IBOutlet var localFolderVC: LocalFolderProviderViewController!
    var currentSourceController: NSViewController?
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var sourceView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectViewControllerAt(index: 0)
    }
    
    func selectViewControllerAt(index: Int) {
        // remove current view controller, if any
        if let currentSourceController = currentSourceController {
            currentSourceController.removeFromParent()
        }
        
        // add new view controller
        if index == 0 {
            // load local folder controller
            currentSourceController = localFolderVC
            self.addChild(currentSourceController!)
            currentSourceController!.view.frame = NSRect(x: 0, y: 0, width: sourceView.frame.width, height: sourceView.frame.height)
            sourceView.addSubview(currentSourceController!.view)
        }
    }
}

extension SourcesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sources.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SourceCell"), owner: nil) as? NSTableCellView else { return nil }
        
        cell.textField?.stringValue = sources[row].name
        cell.imageView?.image = sources[row].image
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("Table selection notification")
        guard let tableView = notification.object as? NSTableView, tableView.selectedRow >= 0 else {
                return
        }
        
        selectViewControllerAt(index: tableView.selectedRow)
    }
}
