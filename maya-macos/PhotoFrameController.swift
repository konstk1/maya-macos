//
//  PhotoFrameWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class PhotoFrameWindowController: NSWindowController, NSWindowDelegate {
    let provider = LocalFolderPhotoProvider()
    
    private var photoView: PhotoView!
    
    private let photoHorizontalPadding: CGFloat = 5.0
    private let photoVerticalPadding: CGFloat = 5.0
    
    lazy var windowSize: NSSize = {
        return window?.frame.size ?? NSMakeSize(200, 200)
    }()
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else { return }
        
        photoView = PhotoView()
        photoView.imageScaling = .scaleProportionallyUpOrDown

        window.contentView?.addSubview(photoView)
        window.isMovableByWindowBackground = true
        window.delegate = self
    }
    
    func show() {
        guard let window = window else {
            log.error("Window is nil")
            return
        }
        
        let image = provider.nextImage()
        photoView.image = image
        
        window.aspectRatio = image.size
        
        var frameSize = windowSize
        
        // determine photo view size based on max window dimmension
        if image.size.width > image.size.height  {
            // landscape (clamp width, calculate height)
            frameSize.height = image.size.height / image.size.width * windowSize.width
        } else {
            // portrait (clamp height, calculate width)
            frameSize.width = image.size.width / image.size.height * windowSize.height
        }
        
        photoView.frame = NSRect(x: photoHorizontalPadding, y: photoVerticalPadding, width: frameSize.width - 2 * photoHorizontalPadding, height: frameSize.height - 2 * photoVerticalPadding)
//        photoView.setFrameSize(NSMakeSize(frameSize.width - 2.0 * photoHorizontalPadding, frameSize.height - 2.0 * photoVerticalPadding))

        window.setFrame(NSRect(origin: window.frame.origin, size: frameSize), display: true)
        
        print("Image: \(image.size)")
        print("View: \(photoView.contentImageSize)")
        print("View: \(photoView.frame.size)")
        print("Window: \(window.frame.size)")
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        print("Showing window")
    }
    
    override func close() {
        super.close()
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
//        print("Resizing \(frameSize)")
        let photoVerticalPadding = 5.0 as CGFloat
        let photoHorizontalPadding = 5.0 as CGFloat
        photoView.setFrameSize(NSMakeSize(frameSize.width - 2.0 * photoHorizontalPadding, frameSize.height - 2.0 * photoVerticalPadding))
        return frameSize
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        guard let window = window else { return }
        print("Resized \(window.frame)")
        windowSize = window.frame.size
    }
    func windowDidResize(_ notification: Notification) {
    }
}

class PhotoWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
}

class PhotoView: NSImageView {
    override var mouseDownCanMoveWindow: Bool { return true }
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
