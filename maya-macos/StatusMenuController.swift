//
//  StatusMenuController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let photoFrame = PhotoFrameWindowController(windowNibName: "PhotoFrameController")
    
    let mouseEventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
    
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    override func awakeFromNib() {
        if let button = statusItem.button {
            button.title = "Maya"
        }
        statusItem.menu = statusMenu

        NSEvent.addLocalMonitorForEvents(matching: mouseEventMask, handler: localEventHandler)
    }
    
    func globalEventHandler(event: NSEvent) {
        print("Global \(event.debugDescription)")
        closePopover()
    }
    
    func localEventHandler(event: NSEvent) -> NSEvent? {
        print("Event \(event) \(event.locationInWindow)")
        guard let button = statusItem.button else { return event }
        
        var blockEvent = false      // indicates if intercepted event should be propagaged
        
        button.isHighlighted = true
        
        // close popover if clicked on status item or outside the photo frame
        // don't close and forward event if clicked inside photo frame window
        if event.type == .leftMouseDown && event.window != photoFrame.window {
            togglePopover()
            blockEvent = true       // don't propagate this any further
        }
        
        button.isHighlighted = false
        
        return blockEvent ? nil : event
    }
    
    func togglePopover() {
        if photoFrame.window?.isVisible == true {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            photoFrame.window?.makeKeyAndOrderFront(nil)
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEventMask, handler: globalEventHandler)
        }
    }
    
    func closePopover() {
        photoFrame.close()
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}

