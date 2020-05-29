//
//  Utilities.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/17/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import SwiftUI

func + (lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

extension NSImageView {
    var contentImageSize: NSSize {
        guard let image = image else { return bounds.size }
        guard imageScaling == .scaleProportionallyUpOrDown || imageScaling == .scaleProportionallyDown else { return bounds.size }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds.size }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        return NSSize(width: image.size.width * scale, height: image.size.height * scale)
    }
}

extension Color {
    static let mayaRed = Color("MayaRed")
    static let mayaGreen = Color("MayaGreen")
    static let mayaBlue = Color("MayaBlue")
}

extension NSImage {
    // swiftlint:disable force_unwrapping
    static let checkbox = NSImage(named: NSImage.menuOnStateTemplateName)!
    static let everyone = NSImage(named: NSImage.everyoneName)!
    static let play = NSImage(named: NSImage.slideshowTemplateName)!
    // swiftlint:enable force_unwrapping
}
