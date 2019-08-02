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
    
    // App
    @IBOutlet weak var openAtLoginCheckbox: NSButton!
    
    // Frame
    @IBOutlet weak var popupWindowCheckbox: NSButton!
    @IBOutlet weak var autoCloseCheckbox: NSButton!
    @IBOutlet weak var autoCloseAfterDropdown: NSPopUpButton!
    
    // Photos
    @IBOutlet weak var autoSwitchPhotosCheckbox: NSButton!
    @IBOutlet weak var autoSwitchPhotosTimeField: NSTextField!
    @IBOutlet weak var autoSwitchPhotosTimeStepper: NSStepper!
    @IBOutlet weak var autoSwitchPhotosTimeUnitsDropdown: NSPopUpButton!
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        guard let toolbar = window?.toolbar else { return }
        
        loadAppSettings()
        loadFrameSettings()
        loadPhotoSettings()
        
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier("ToolbarGeneralItem")
        setWindowContent(to: generalView)
    }
    
    func loadAppSettings() {
        openAtLoginCheckbox.state = Settings.App.openAtLogin ? .on : .off
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
        print("View size \(view.frame.size)")
        guard let window = window else { return }
        
        // save these before setting content view because setting content view changes these
        let contentSize = view.frame.size
        let windowOrigin = window.frame.origin
        
        // adjust vertical position to keep top left corner stationary
        // the delta is the different between current content height and new content height
        let deltaY = (window.contentView?.frame.height ?? 0) - contentSize.height
        
        // calculate new frame origin and frame based on new content size
        let origin = NSPoint(x: windowOrigin.x, y: windowOrigin.y + deltaY)
        let windowSize = window.frameRect(forContentRect: NSRect(origin: origin, size: contentSize)).size
        let frame = NSRect(origin: origin, size: windowSize)
        
        // clear out the content before switching,
        // then change window frame and set new content
        window.contentView = nil
        window.setFrame(frame, display: false, animate: true)
        window.contentView = view
    }
    
    @IBAction func openAtLoginToggled(_ sender: NSButton) {
        print("Open at login \(sender.state == .on)")
        Settings.App.openAtLogin = (sender.state == .on)
    }
}

// MARK: - Frame Settings Actions
extension SettingsController {
    func loadFrameSettings() {
        popupWindowCheckbox.state = Settings.Frame.popupFrame ? .on : .off
        autoCloseCheckbox.state = Settings.Frame.autoCloseFrame ? .on : .off
        
        // TODO: implement dropdown settings
    }
    
    @IBAction func popupWindowToggled(_ sender: NSButton) {
        Settings.Frame.popupFrame = (sender.state == .on)
        // TODO: implement this
    }
    
    @IBAction func autoCloseToggled(_ sender: NSButton) {
        Settings.Frame.autoCloseFrame = (sender.state == .on)
        // TODO: implement this
    }
    
    @IBAction func autoCloseTimeSelected(_ sender: NSPopUpButton) {
        print("Close after \(sender.titleOfSelectedItem)")
    }
}

// MARK: - Photo Settings Actions
extension SettingsController {
    func loadPhotoSettings() {
        autoSwitchPhotosCheckbox.state = Settings.Photos.autoSwitchPhoto ? .on : .off
        autoSwitchPhotosTimeField.integerValue = Settings.Photos.autoSwitchPhotoAfter.value
        autoSwitchPhotosTimeStepper.integerValue = Settings.Photos.autoSwitchPhotoAfter.value
        autoSwitchPhotosTimeUnitsDropdown.selectItem(withTitle: Settings.Photos.autoSwitchPhotoAfter.unit.rawValue)
    }
    
    func updateAutoSwitchPhotoTime() {
        guard let units = autoSwitchPhotosTimeUnitsDropdown.titleOfSelectedItem else {
            log.error("autoSwitchPhotosTimeUnitsDropdown selected item is nil")
            return
        }
        
        let value = autoSwitchPhotosTimeStepper.integerValue
        
        var autoSwitchTime: TimePeriod
        
        switch units {
        case "minutes":
            autoSwitchTime = .minutes(value)
        case "hours":
            autoSwitchTime = .hours(value)
        case "days":
            autoSwitchTime = .days(value)
        default:
            log.warning("Unexpected value for autoSwitchPhotosTimeUnitsDropdown")
            return
        }
        
        Settings.Photos.autoSwitchPhotoAfter = autoSwitchTime
    }
    
    @IBAction func switchPhotosToggled(_ sender: NSButton) {
        Settings.Photos.autoSwitchPhoto = (sender.state == .on)
        // TODO: implement this
    }
    
    @IBAction func switchPhotosTimeEntered(_ sender: NSTextField) {
        print("Time entered \(sender.stringValue)")
        guard let value = Int(autoSwitchPhotosTimeField.stringValue) else {
            log.warning("Non integer value for photo time \(autoSwitchPhotosTimeField.stringValue)")
            return
        }
        
        autoSwitchPhotosTimeStepper.integerValue = value  // sync stepper with text
        updateAutoSwitchPhotoTime()
    }
    
    @IBAction func switchPhotosTimeStepped(_ sender: NSStepper) {
        print("Stepper \(sender.integerValue)")
        
        autoSwitchPhotosTimeField.integerValue = sender.integerValue // sync text with stepper
        updateAutoSwitchPhotoTime()
    }
    
    @IBAction func switchPhotosTimeUnitsChosen(_ sender: NSPopUpButton) {
        updateAutoSwitchPhotoTime()
    }
}
