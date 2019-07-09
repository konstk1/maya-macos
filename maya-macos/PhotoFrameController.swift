//
//  PhotoFrameWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class PhotoFrameWindowController: NSWindowController {
    let provider = LocalFolderPhotoProvider()
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.isMovableByWindowBackground = true
    }
    
}

class PhotoWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
}

class PhotoView: NSImageView {
    override var mouseDownCanMoveWindow: Bool { return true }
}

