//
//  PhotoFrameWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

class PhotoWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
}

class PhotoView: NSImageView {
    override var mouseDownCanMoveWindow: Bool { return true }
}

class PhotoFrameWindowController: NSWindowController {
    // Photo vendor properties
    private let photoVendor = PhotoVendor()
    private var currentPhoto: NSImage = NSImage(named: NSImage.everyoneName)!
    private var vendTimer: Timer?
    
    // Photo frame properties
    private var photoView: PhotoView!
    
    private let photoHorizontalPadding: CGFloat = 5.0
    private let photoVerticalPadding: CGFloat = 5.0
    
    // Window properties
    lazy var windowSize: NSSize = {
        return window?.frame.size ?? NSSize(width: 200, height: 200)  // TODO: persist this
    }()
    
    /// Offset of the top left corner from the reference window specified in show(relativeTo:)
    private var windowOffset: NSPoint =  NSPoint(x: 0, y: -1)    // TODO: persist windowOffset
    
    weak var referenceWindow: NSWindow?
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    private var observers: [NSKeyValueObservation] = []
    
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
        photoVendor.vendImage()
        
        observers = [
            Settings.photos.observe(\.autoSwitchPhoto, options: [.initial, .new], changeHandler: { [weak self] (_, _) in
                self?.updatePhotoTiming()
            }),
            Settings.photos.observe(\.autoSwitchPhotoPeriod, options: [.initial, .new], changeHandler: { [weak self] (_, _) in
                self?.updatePhotoTiming()
            })
        ]
    }
    
    func updatePhotoTiming() {
        print("New photo switch settings")
        
        if Settings.photos.autoSwitchPhoto {
            vendTimer = Timer.scheduledTimer(withTimeInterval: Settings.photos.autoSwitchPhotoPeriod.timeInterval, repeats: true, block: { [weak self] (_) in
                self?.photoVendor.vendImage()
            })
        }
    }
}

extension PhotoFrameWindowController: PhotoVendorDelegate {
    func didVendNewImage(image: NSImage) {
        currentPhoto = image
    }
    
    func didFailToVend(error: Error?) {
        // TODO: implement this
        currentPhoto = NSImage(named: NSImage.everyoneName)!
    }
}

// MARK: Window related methods
extension PhotoFrameWindowController: NSWindowDelegate {
    func show(relativeTo referenceWindow: NSWindow?) {
        guard let window = window else {
            log.error("Window is nil")
            return
        }
        
        self.referenceWindow = referenceWindow
        
        photoView.image = currentPhoto
        
        window.aspectRatio = currentPhoto.size
        
        var frameSize = windowSize
        
        // determine photo view size based on max window dimmension
        if currentPhoto.size.width > currentPhoto.size.height  {
            // landscape (clamp width, calculate height)
            frameSize.height = currentPhoto.size.height / currentPhoto.size.width * windowSize.width
        } else {
            // portrait (clamp height, calculate width)
            frameSize.width = currentPhoto.size.width / currentPhoto.size.height * windowSize.height
        }
        
        photoView.frame = NSRect(x: photoHorizontalPadding, y: photoVerticalPadding, width: frameSize.width - 2 * photoHorizontalPadding, height: frameSize.height - 2 * photoVerticalPadding)
        
        // set window position based on offset from reference window (which is usually status menu item)
        var windowOrigin = window.frame.origin
        if let referenceWindow = referenceWindow {
            windowOrigin = referenceWindow.frame.origin + windowOffset
            windowOrigin.y -= frameSize.height
        }
        window.setFrame(NSRect(origin: windowOrigin, size: frameSize), display: true)
        
        // show window on top of everything
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        // this will trigger popup when next image is fetched
        // TODO: can this be less cludgy?
        photoVendor.vendImage()
    }
    
    override func close() {
        super.close()
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // resize photoView to track window size with specified padding
        photoView.setFrameSize(NSMakeSize(frameSize.width - 2.0 * photoHorizontalPadding, frameSize.height - 2.0 * photoVerticalPadding))
        return frameSize
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        guard let window = window else { return }
        // save window size so the frame always opens with same size
        windowSize = window.frame.size
    }

    func windowDidMove(_ notification: Notification) {
        // track offset of top left corner from origin so the frame always opens in the same location
        guard let window = window, let referenceWindow = referenceWindow else { return }
        windowOffset = window.frame.origin - referenceWindow.frame.origin
        windowOffset.y += window.frame.height
        print("Moved \(window.frame.origin), new offset \(windowOffset)")
        
    }
}


