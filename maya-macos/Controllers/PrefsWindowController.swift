//
//  PrefsWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/13/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import SwiftUI

class PrefsWindowController: NSWindowController, NSWindowDelegate {

    init() {
        let prefsView = PreferencesView().environmentObject(PhotoVendor.shared)
        let hostingController = NSHostingController(rootView: prefsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Maya - Preferences"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(named: "TabBarBackground")
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.center()
        window.setFrameAutosaveName("Prefs window")
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
