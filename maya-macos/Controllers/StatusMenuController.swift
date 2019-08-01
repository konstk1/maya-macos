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
    
    lazy var photoFrame = { PhotoFrameWindowController(windowNibName: "PhotoFrameController") }()
    lazy var prefController = { SettingsController(windowNibName: "SettingsController") }()
    
    let mouseEventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
    
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    override func awakeFromNib() {
        if let icon = NSImage(named: "StatusIcon") {
//            icon.isTemplate = true
            statusItem.button?.image = icon
        } else {
            statusItem.button?.title = "Maya"
        }
        statusItem.menu = statusMenu

        NSEvent.addLocalMonitorForEvents(matching: mouseEventMask, handler: localEventHandler)
    }
    
    func globalEventHandler(event: NSEvent) {
        closePopover()
    }
    
    func localEventHandler(event: NSEvent) -> NSEvent? {
        // if we get a local left click in the status item button, toggle the popover
        // and block left click from being propagated
        // if the click is out the photo frame, close the popover and propagate the event
        // otherwise, do nothing and simply propagate the event
        
        /// indicates if intercepted event should be propagaged
        var blockEvent = false
        
        // close popover if clicked on status item or outside the photo frame
        // don't close and forward event if clicked inside photo frame window
        if event.type == .leftMouseDown {
//            print("Event screen \(event.window?.screen?.frame)")
//            print("Button screen \(statusItem.button?.window?.frame)")
            if event.window == statusItem.button?.window {
                togglePopover()
                blockEvent = true    // don't propagate this event any further
            } else if event.window != photoFrame.window && photoFrame.isVisible {
                closePopover()
            }
        }
        
        return blockEvent ? nil : event
    }
    
    func togglePopover() {
        if photoFrame.isVisible == true {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        photoFrame.show(relativeTo: statusItem.button?.window)
        statusItem.button?.isHighlighted = true
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEventMask, handler: globalEventHandler)
    }
    
    func closePopover() {
        photoFrame.close()
        statusItem.button?.isHighlighted = false
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
        }
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        prefController.showWindow(sender)
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}

