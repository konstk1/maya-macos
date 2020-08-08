//
//  HelpWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/15/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import SwiftUI
import SwiftyBeaver

class HelpWindowController: NSWindowController, NSWindowDelegate {

    init() {
        let helpView = HelpView()
        let hostingController = NSHostingController(rootView: helpView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Tutorial"
        window.titlebarAppearsTransparent = true
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.center()
        window.setFrameAutosaveName("Help window")
        super.init(window: window)

        window.delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        print("Destroying vc")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }

    func windowWillClose(_ notification: Notification) {
    }
}
