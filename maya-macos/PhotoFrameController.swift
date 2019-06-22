//
//  PhotoFrameWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class PhotoFrameWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
       window?.isMovableByWindowBackground = true
    }
    
}
