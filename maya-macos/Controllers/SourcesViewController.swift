//
//  SourcesViewController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/11/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class SourcesViewController: NSViewController {
    lazy var sources = {
        [
            (name: "Local Folder", image: NSImage(named: NSImage.folderName)),
            (name: "Google Photos", image: NSImage(named: NSImage.everyoneName))
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
}
