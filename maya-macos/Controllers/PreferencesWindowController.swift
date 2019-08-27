//
//  SettingsController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/18/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    lazy var sourcesViewController = SourcesViewController(nibName: NSNib.Name("SourcesViewController"), bundle: nil)
    
    @IBOutlet var generalView: NSView!
    
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
        openAtLoginCheckbox.state = Settings.app.openAtLogin ? .on : .off
    }
    
    @IBAction func generalPressed(_ sender: NSToolbarItem) {
        setWindowContent(to: generalView)
    }
    
    @IBAction func sourcesPressed(_ sender: NSToolbarItem) {
        setWindowContent(to: sourcesViewController.view)
    }
    
    func setWindowContent(to view: NSView) {
//        print("View size \(view.frame.size)")
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
        Settings.app.openAtLogin = (sender.state == .on)
    }
}

// MARK: - Frame Settings Actions
extension PreferencesWindowController {
    private var autoCloseTimeOptions: [TimePeriod] {
        [.seconds(5), .seconds(10), .seconds(15), .seconds(30), .seconds(60)]
    }
    
    func loadFrameSettings() {
        popupWindowCheckbox.state = Settings.frame.popupFrame ? .on : .off
        autoCloseCheckbox.state = Settings.frame.autoCloseFrame ? .on : .off
                
        // remove any items popuplated in XIB
        autoCloseAfterDropdown.removeAllItems()
        
        autoCloseAfterDropdown.addItems(withTitles: autoCloseTimeOptions.map { $0.description })
        
        autoCloseAfterDropdown.selectItem(withTitle: Settings.frame.autoCloseFrameAfter.description)
        
    }
    
    @IBAction func popupWindowToggled(_ sender: NSButton) {
        Settings.frame.popupFrame = (sender.state == .on)
    }
    
    @IBAction func autoCloseToggled(_ sender: NSButton) {
        Settings.frame.autoCloseFrame = (sender.state == .on)
    }
    
    @IBAction func autoCloseTimeSelected(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else {
            log.warning("Nothing selected in autoCloseAfterDropdown")
            return
        }
        
        Settings.frame.autoCloseFrameAfter = autoCloseTimeOptions[sender.indexOfSelectedItem]
        log.info("New settings: auto-close frame after \(Settings.frame.autoCloseFrameAfter)")
    }
}

// MARK: - Photo Settings Actions
extension PreferencesWindowController {
    func loadPhotoSettings() {
        // populate units dropdown
        let unitsItems: [TimeUnit] = [.seconds, .minutes, .hours, .days]
        autoSwitchPhotosTimeUnitsDropdown.removeAllItems()  // remove any items populated from XIB
        autoSwitchPhotosTimeUnitsDropdown.addItems(withTitles: unitsItems.map { $0.rawValue })
        
        autoSwitchPhotosCheckbox.state = Settings.photos.autoSwitchPhoto ? .on : .off
        autoSwitchPhotosTimeField.integerValue = Settings.photos.autoSwitchPhotoPeriod.value
        autoSwitchPhotosTimeStepper.integerValue = Settings.photos.autoSwitchPhotoPeriod.value
        autoSwitchPhotosTimeUnitsDropdown.selectItem(withTitle: Settings.photos.autoSwitchPhotoPeriod.unit.rawValue)
    }
    
    func updateAutoSwitchPhotoTime() {
        guard let titleOfSelectedItem = autoSwitchPhotosTimeUnitsDropdown.titleOfSelectedItem,
              let unit = TimeUnit(rawValue: titleOfSelectedItem) else {
            log.error("autoSwitchPhotosTimeUnitsDropdown selected item is nil or invalid")
            return
        }
        
        let value = autoSwitchPhotosTimeStepper.integerValue
        
        var autoSwitchTime: TimePeriod
        
        switch unit {
        case .seconds:
            autoSwitchTime = .seconds(value)
        case .minutes:
            autoSwitchTime = .minutes(value)
        case .hours:
            autoSwitchTime = .hours(value)
        case .days:
            autoSwitchTime = .days(value)
        }
        
        Settings.photos.autoSwitchPhotoPeriod = autoSwitchTime
    }
    
    @IBAction func switchPhotosToggled(_ sender: NSButton) {
        Settings.photos.autoSwitchPhoto = (sender.state == .on)
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
