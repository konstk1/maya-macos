//
//  SourceCell.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/27/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa

class SourceCell: NSTableCellView {
    @IBOutlet weak var activateButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var photoCountLabel: NSButton!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}
