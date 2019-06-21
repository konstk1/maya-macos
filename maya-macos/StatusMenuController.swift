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
    
    let popover = NSPopover()
    
    let mouseEventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
    
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    override func awakeFromNib() {
        if let button = statusItem.button {
            button.title = "Maya"
        }
        statusItem.menu = statusMenu
        
        popover.contentViewController = PhotoFrameController(nibName: "PhotoFrameController", bundle: nil)

        NSEvent.addLocalMonitorForEvents(matching: mouseEventMask, handler: localEventHandler)
    }
    
    func globalEventHandler(event: NSEvent) {
        closePopover()
    }
    
    func localEventHandler(event: NSEvent) -> NSEvent? {
//        print("Event \(event.debugDescription)")
        guard let button = statusItem.button else { return event }
        
        var blockEvent = false      // indicates if intercepted event should be propagaged
        
        button.isHighlighted = true
        
        if event.type == .leftMouseDown {
            togglePopover()
            blockEvent = true       // don't propagate this any further
        }
        
        button.isHighlighted = false
        
        return blockEvent ? nil : event
    }
    
    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEventMask, handler: globalEventHandler)
        }
    }
    
    func closePopover() {
        popover.close()
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}

