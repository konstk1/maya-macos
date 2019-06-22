//
//  PhotoWindow.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/22/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class PhotoWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
}

class PhotoView: NSImageView {
    override var mouseDownCanMoveWindow: Bool { return true }
}
