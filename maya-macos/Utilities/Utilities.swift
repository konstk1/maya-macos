//
//  Utilities.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/17/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import SwiftUI
import SwiftyBeaver

func + (lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func + (lhs: NSSize, rhs: CGFloat) -> NSSize {
    return NSSize(width: lhs.width + rhs, height: lhs.height + rhs)
}

func - (lhs: NSSize, rhs: CGFloat) -> NSSize {
    return NSSize(width: lhs.width - rhs, height: lhs.height - rhs)
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

extension TimeInterval {
    var labelString: String {
        // swiftlint:disable identifier_name
        var secs = Int(self)
        let h = secs / 3600
        secs -= h * 3600
        let m = secs / 60
        secs -= m * 60
        let s = secs

        if h > 0 {
            return "\(h)h \(m)m"
        } else if m > 0 {
            return "\(m)m \(s)s"
        } else {
            return "\(s) sec"
        }
        // swiftlint:enable identifier_name
    }
}

extension Color {
    static let helpText = Color("HelpTextPrimary")
    static let mayaRed = Color("MayaRed")
    static let mayaGreen = Color("MayaGreen")
    static let mayaBlue = Color("MayaBlue")
    static let prefsBackground = Color("PrefsBackground")
    static let tabBarBackground = Color("TabBarBackground")
    static let tabBarSelected = Color("TabBarSelected")

}

extension NSImage {
    // swiftlint:disable force_unwrapping
    static let checkbox = #imageLiteral(resourceName: "Checkmark")
    static let everyone = NSImage(named: NSImage.everyoneName)!
    static let play = NSImage(named: NSImage.slideshowTemplateName)!
    static let mayaLogo = #imageLiteral(resourceName: "Maya Logo")
    // swiftlint:enable force_unwrapping
}

func sendFeedback() {
    let service = NSSharingService(named: .composeEmail)
    service?.recipients = ["feedback@konst.dev"]
    service?.subject = "May Frame Feedback"

    if let logFileDest = log.destinations.first(where: { $0 is FileDestination }) as? FileDestination,
        let logFileUrl = logFileDest.logFileURL {
        service?.perform(withItems: [logFileUrl])
    } else {
        service?.perform(withItems: [])
    }
}
