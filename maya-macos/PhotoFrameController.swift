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
    
    @IBOutlet weak var photoImage: NSImageCell!
    @IBOutlet weak var imageView: PhotoView!
    
    let minWindowSize = NSSize(width: 200, height: 200)
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
//    init() {
//        print("Init")
//        window = PhotoWindow(contentRect: <#T##NSRect#>, styleMask: <#T##NSWindow.StyleMask#>, backing: <#T##NSWindow.BackingStoreType#>, defer: <#T##Bool#>, screen: <#T##NSScreen?#>)
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        photoImage =
        window?.contentView =
//        window?.setContentSize(window!.frame.size)
        window?.isMovableByWindowBackground = true
        window?.delegate = self
    }
    
    func show() {
        guard let window = window else {
            log.error("Window is nil")
            return
        }
        
        let image = provider.nextImage()
        imageView.image = image
        
        window.aspectRatio = image.size
        imageView.setFrameSize(imageView.contentImageSize)
//        window.setFrame(NSRect(origin: window.frame.origin, size: imageView.contentImageSize), display: true)
        
        print("Image: \(image.size)")
        print("View: \(imageView.contentImageSize)")
        print("View: \(imageView.frame.size)")
        print("Window: \(window.frame.size)")
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        print("Showing window")
    }
    
    override func close() {
        super.close()
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        print("Resizing \(frameSize)")
        return frameSize
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
