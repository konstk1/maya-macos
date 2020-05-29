//
//  PhotoScrollView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 11/24/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa

class PhotoScrollView: NSScrollView {

    // drag state for scrolling
    var dragPrevEvNum: Int = 0
    var dragPrevLoc: NSPoint = .zero

    /// Set document cursor based on mouse events and zoom level.
    /// While zoomed, use open and closed hand to indicate dragging,
    /// otherwise, show arrow.
    func updateCursor(event: NSEvent) {
        if magnification > 1 {
            if event.type == .leftMouseDown {
                documentCursor = .closedHand
            } else if event.type == .leftMouseUp {
                documentCursor = .openHand
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            doubleClicked(locationInWindow: event.locationInWindow)
        }

        updateCursor(event: event)

        // propagate to photo frame
        superview?.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        updateCursor(event: event)
    }

    override func mouseDragged(with event: NSEvent) {
        if dragPrevEvNum != event.eventNumber {
            dragPrevLoc = event.locationInWindow
            dragPrevEvNum = event.eventNumber
        }

        let locInView = contentView.convert(event.locationInWindow, from: nil)
        let delta = locInView - contentView.convert(dragPrevLoc, from: nil)
        //        log.verbose("Dragged \(delta)")

        var newOrigin = contentView.bounds.origin - delta

        // clip from scrolling past the content
        newOrigin.x = max(newOrigin.x, 0)
        newOrigin.y = max(newOrigin.y, 0)
        newOrigin.x = min(newOrigin.x, contentSize.width - contentView.bounds.size.width)
        newOrigin.y = min(newOrigin.y, contentSize.height - contentView.bounds.size.height)

        // scroll and adjust scrollbars accordingly
        contentView.scroll(to: newOrigin)
        reflectScrolledClipView(contentView)

        dragPrevLoc = event.locationInWindow
    }

    /// Action to perform when photo is double clicked.
    /// Toggle between 3x and 1x zoom.
    func doubleClicked(locationInWindow: NSPoint) {
        log.verbose("Frame double clicked, zooming...")

        var newMagnification: CGFloat
        var newCursor: NSCursor
        var center: NSPoint

        if magnification > 1.0 {
            newMagnification = 1.0
            newCursor = .arrow
            center = NSPoint(x: bounds.midX, y: bounds.midY)
        } else {
            center = contentView.convert(locationInWindow, from: nil)
            newMagnification = 3
            newCursor = .openHand
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            animator().setMagnification(newMagnification, centeredAt: center)
        }, completionHandler: { [weak self] in
            self?.documentCursor = newCursor
        })
    }
}
