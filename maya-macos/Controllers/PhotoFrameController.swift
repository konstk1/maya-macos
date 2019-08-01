//
//  PhotoFrameWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class PhotoFrameWindowController: NSWindowController, NSWindowDelegate {
    let photoVendor = PhotoVendor()
    
    private var photoView: PhotoView!
    
    private let photoHorizontalPadding: CGFloat = 5.0
    private let photoVerticalPadding: CGFloat = 5.0
    
    lazy var windowSize: NSSize = {
        return window?.frame.size ?? NSSize(width: 200, height: 200)
    }()
    
    weak var referenceWindow: NSWindow?
    
    /// Offset of the top left corner from the reference window specified in show(relativeTo:)
    private var windowOffset: NSPoint =  NSPoint(x: 0, y: -1)    // TODO: persist windowOffset
    
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
        
        photoVendor.setProvider(LocalFolderPhotoProvider())
        photoVendor.delegate = self
    }
    
    func show(relativeTo referenceWindow: NSWindow?) {
        self.referenceWindow = referenceWindow
        
        // this will trigger popup when next image is fetched
        // TODO: can this be less cludgy?
        photoVendor.nextImage()
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
    
    func windowWillMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
//        print("Will move \(window.frame)")
//        previousWindowOrigin = window.frame.origin
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = window, let referenceWindow = referenceWindow else { return }
        windowOffset = window.frame.origin - referenceWindow.frame.origin
        windowOffset.y += window.frame.height
        print("Moved \(window.frame.origin), new offset \(windowOffset)")
        
    }
}

extension PhotoFrameWindowController: PhotoVendorDelegate {
    func didVendNewImage(image: NSImage) {
        guard let window = window else {
            log.error("Window is nil")
            return
        }
        
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
        
        var windowOrigin = window.frame.origin
        if let referenceWindow = referenceWindow {
            windowOrigin = referenceWindow.frame.origin + windowOffset
            windowOrigin.y -= frameSize.height
        }
        window.setFrame(NSRect(origin: windowOrigin, size: frameSize), display: true)
        
//        print("Offset \(windowOffset)")
//        print("Window: \(window.frame)")
//        print("Ref Window: \(referenceWindow?.frame)")
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
//        print("Showing window")
    }
    
    func didFailToVend(error: Error?) {
        // TODO: implement this
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
