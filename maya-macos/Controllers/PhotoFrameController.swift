//
//  PhotoFrameWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

extension NSNotification.Name {
    static let photoFrameStatus = NSNotification.Name("photoFrameStatus")
}

enum PhotoFrameStatus {
    case idle
    case scheduled
    case newPhotoReady
}

class PhotoWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
}

class PhotoView: NSImageView {
    override var mouseDownCanMoveWindow: Bool { return true }
}

class PhotoFrameWindowController: NSWindowController {
    // MARK: - Properties
    private(set) var status: PhotoFrameStatus = .idle {
        didSet {
            NotificationCenter.default.post(name: .photoFrameStatus, object: self)
        }
    }
    
    // Photo vendor properties
    private let photoVendor = PhotoVendor.shared
    private var currentPhoto: NSImage = NSImage(named: NSImage.everyoneName)!
    private var vendTimer: Timer?
    
    // Photo frame properties
    private var photoView: PhotoView!
    private var shouldPopupOnVend = false
    
    private let photoHorizontalPadding: CGFloat = 5.0
    private let photoVerticalPadding: CGFloat = 5.0

    // Window properties
    // TODO: move this to Settings
    @UserDefault("PhotoFrame.windowSize", defaultValue: NSSize(width: 400, height: 400))
    private var windowSize
    
    /// Offset of the top left corner from the reference window specified in show(relativeTo:)
    @UserDefault("PhotoFrame.windowOffset", defaultValue: NSPoint(x: 0, y: -1))
    private var windowOffset;
        
    weak var referenceWindow: NSWindow?
    private var globalEventMonitor: Any?

    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    private var observers: [NSKeyValueObservation] = []
    
    override var windowNibName: NSNib.Name? { NSNib.Name("PhotoFrameController") }

    // MARK: Functions
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init()")
    }
    
    init() {
        super.init(window: nil)
        
        photoVendor.setProvider(LocalFolderPhotoProvider.shared)
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
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else { return }
        
        photoView = PhotoView()
        photoView.imageScaling = .scaleProportionallyUpOrDown

        window.contentView?.addSubview(photoView)
        window.isMovableByWindowBackground = true
        window.delegate = self
    }
    
    /// Determines next photo timing.  If auto-switch enabled, [re]sets the timer to vend new image.
    func updatePhotoTiming() {
        // invalidate current timer, if running
        vendTimer?.invalidate()
        
        // set new timer based on settings
        if Settings.photos.autoSwitchPhoto {
            log.info("Auto next photo in \(Settings.photos.autoSwitchPhotoPeriod)")
            vendTimer = Timer.scheduledTimer(withTimeInterval: Settings.photos.autoSwitchPhotoPeriod.timeInterval, repeats: false, block: { [weak self] (_) in
                self?.shouldPopupOnVend = Settings.frame.popupFrame
                self?.photoVendor.vendImage()
            })
        } else {
            log.info("Auto photo switch off")
        }
        
        // update status but don't override .newPhotoReady status, it'll be cleared when frame is closed
        if status != .newPhotoReady {
            status = (vendTimer?.isValid == true) ? .scheduled : .idle
        }
    }
    
    func forceNext() {
        shouldPopupOnVend = true
        photoVendor.vendImage()
    }
    
    func globalEventHandler(event: NSEvent) {
        close()
    }
}

// MARK: - PhotoVendorDelegate
extension PhotoFrameWindowController: PhotoVendorDelegate {
    func didVendNewImage(image: NSImage) {
        log.verbose("Vending new image")
        currentPhoto = image
        
        status = .newPhotoReady
        
        if shouldPopupOnVend {
            log.verbose("Auto poping up frame")
            // reset popup flag, this will be set to true by the auto switch timer
            shouldPopupOnVend = false
            show(relativeTo: referenceWindow)
            
            // if auto-close is enabled, set timer to trigger frame close
            if Settings.frame.autoCloseFrame {
                // TODO: can this be improved? buggy if close period is greater than vend period
                DispatchQueue.main.asyncAfter(deadline: .now() + Settings.frame.autoCloseFrameAfter.timeInterval) { [weak self] in
                    log.verbose("Auto-closing")
                    self?.close()
                }
            }
        }
        
        // restart photo timers
        updatePhotoTiming()
    }
    
    func didFailToVend(error: Error?) {
        // TODO: implement this
        currentPhoto = NSImage(named: NSImage.everyoneName)!
    }
}

// MARK: - Window related methods
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
        
        // only install global event monitor if not already installed
        // any clicks outside the window will trigger frame to close
        if globalEventMonitor == nil {
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: globalEventHandler)
        }
    }
    
    override func close() {
        super.close()
        
        status = (vendTimer?.isValid == true) ? .scheduled : .idle
        
        // remove the global event monitor when frame is closed
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            // clear out event monitor to indicate it's no longer installed
            self.globalEventMonitor = nil
        }
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
//        print("Moved \(window.frame.origin), new offset \(windowOffset)")
    }
}

