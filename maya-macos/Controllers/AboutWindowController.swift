//
//  AboutWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/15/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import SwiftyBeaver

class AboutWindowController: NSWindowController {
    
    @IBOutlet weak var logButton: NSButton!
    
    var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }

    @IBOutlet weak var versionLabel: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        versionLabel.stringValue = "Version \(appVersion)"
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        logButton.title = "Copy log path"
    }
        
    @IBAction func copyLogPathClicked(_ sender: NSButton) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.declareTypes([.string], owner: nil)
        
        let fileDestinations = log.destinations.compactMap { $0 as? FileDestination }
        
        var status = "Copied!"

        if let logFilePath = fileDestinations.first?.logFileURL?.path {
            if !pasteBoard.setString(logFilePath, forType: .string) {
                status = "Copy Failed!"
            }
        } else {
            status = "No log file!"
        }
        
        logButton.title = status
    }
}
