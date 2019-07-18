//
//  SettingsController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/18/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class SettingsController: NSWindowController, NSWindowDelegate {
    @IBOutlet var generalView: NSView!
    @IBOutlet var sourcesView: NSView!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        guard let toolbar = window?.toolbar else { return }
//        generalPressed(toolbar.items[0])
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier("ToolbarGeneralItem")
        setWindowContent(to: generalView)
    }
    
    @IBAction func generalPressed(_ sender: NSToolbarItem) {
        print("General")
        setWindowContent(to: generalView)
    }
    
    @IBAction func sourcesPressed(_ sender: NSToolbarItem) {
        print("Sources")
        setWindowContent(to: sourcesView)
    }
    
    func setWindowContent(to view: NSView) {
        print("Sources size \(sourcesView.frame.size)")
        guard let window = window else { return }
        
        // save these before setting content view because setting content view changes these
        let contentSize = view.frame.size
        let windowOrigin = window.frame.origin
        
        // adjust vertical position to keep top left corner stationary
        // the delta is the different between current content height and new content height
        let deltaY = (window.contentView?.frame.height ?? 0) - contentSize.height
        
        window.contentView = view
        window.setContentSize(contentSize)
        window.setFrameOrigin(NSPoint(x: windowOrigin.x, y: windowOrigin.y + deltaY))
    }
}
