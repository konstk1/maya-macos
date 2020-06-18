//
//  PhotoFrameWindowController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/21/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine

extension NSNotification.Name {
    static let photoFrameStatus = NSNotification.Name("photoFrameStatus")
    static let prefsWindowRequested = NSNotification.Name("prefsWindowRequested")
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

class PhotoFrameWindowController: NSWindowController, ObservableObject {
    // MARK: - Properties
    private(set) var status: PhotoFrameStatus = .idle {
        didSet {
            NotificationCenter.default.post(name: .photoFrameStatus, object: self)
        }
    }

    // Photo vendor properties
    private let photoVendor = PhotoVendor.shared
    // TODO: replace this with another placeholder image
    private var currentPhoto: NSImage = NSImage(named: NSImage.everyoneName)!   // swiftlint:disable:this force_unwrapping
    private var vendTimer: Timer?

    // Photo frame properties
    @IBOutlet weak var scrollView: PhotoScrollView!

    private var photoView: PhotoView!
    private var shouldPopupOnVend = false
    private var shouldAutoClose = true

    let borderSize: CGFloat = 10.0

    // Window properties
    // TODO: move this to Settings
    @PublishedUserDefault("PhotoFrame.windowSize", defaultValue: NSSize(width: 400, height: 400))
    private var windowSize

    /// Offset of the top left corner from the reference window specified in show(relativeTo:)
    @PublishedUserDefault("PhotoFrame.windowOffset", defaultValue: NSPoint(x: 0, y: -1))
    private var windowOffset

    weak var referenceWindow: NSWindow?
    private var globalEventMonitor: Any?

    var isVisible: Bool {
        return window?.isVisible ?? false
    }

    private var isAnimating = false
    private var animationStartFrame: NSRect {
        if let frame = referenceWindow?.frame {
            return NSRect(x: frame.midX, y: frame.midY, width: borderSize, height: borderSize)
        } else {
            return NSRect(x: 0, y: 0, width: borderSize, height: borderSize)
        }
    }

    private var observers: [NSKeyValueObservation] = []
    private var subs: Set<AnyCancellable> = []

    var autoCloseWorkItem: DispatchWorkItem?

    override var windowNibName: NSNib.Name? { NSNib.Name("PhotoFrameController") }

    // MARK: Functions

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init()")
    }

    init() {
        super.init(window: nil)

        if isUnitTesting {
            return
        }

        photoVendor.add(provider: LocalFolderPhotoProvider())
        photoVendor.add(provider: ApplePhotoProvider())
//        photoVendor.add(provider: GooglePhotoProvider())

        photoVendor.loadActiveProviderFromSettings()

        // subscribe to new images
        photoVendor.$currentImage.compactMap { $0 }.receive(on: RunLoop.main).sink { [weak self] image in
            self?.didVendNewImage(image: image)
        }.store(in: &subs)

        photoVendor.$error.receive(on: RunLoop.main).sink { [weak self] error in
            if let error = error {
                self?.didFailToVend(error: error)
            }
        }.store(in: &subs)

        Settings.photos.$autoSwitchPhoto.sink { [weak self] in
            self?.updatePhotoTiming(autoSwitchPhoto: $0, autoSwitchPeriod: Settings.photos.autoSwitchPhotoPeriod)

        }.store(in: &subs)

        Settings.photos.$autoSwitchPhotoPeriod.sink { [weak self] in
            self?.updatePhotoTiming(autoSwitchPhoto: Settings.photos.autoSwitchPhoto, autoSwitchPeriod: $0)
        }.store(in: &subs)

        window?.acceptsMouseMovedEvents = true
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        guard let window = window else { return }
        window.backgroundColor = .clear

        photoView = PhotoView()
        photoView.imageScaling = .scaleProportionallyUpOrDown

        scrollView.documentView = photoView
        scrollView.postsBoundsChangedNotifications = true

//        window.isMovableByWindowBackground = true
        window.delegate = self
    }

    override func mouseDown(with event: NSEvent) {
        print("Frame clicked, cancelling auto close...")
        autoCloseWorkItem?.cancel()

        // if image is fully zoomed out, move the window, otherwise let the scroll view handle scrolling
        if scrollView.magnification <= 1.0 {
            window?.performDrag(with: event)
        }
    }

    /// Determines next photo timing.  If auto-switch enabled, [re]sets the timer to vend new image.
    func updatePhotoTiming(autoSwitchPhoto: Bool, autoSwitchPeriod: TimePeriod) {
        // invalidate current timer, if running
        vendTimer?.invalidate()

        // set new timer based on settings
        if autoSwitchPhoto {
            log.info("Auto next photo in \(autoSwitchPeriod)")
            vendTimer = Timer.scheduledTimer(withTimeInterval: autoSwitchPeriod.timeInterval, repeats: false, block: { [weak self] (_) in
                self?.shouldPopupOnVend = (Settings.frame.newPhotoAction == .popupFrame)
                self?.photoVendor.vendImage(shouldRefresh: true)
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
        // when user forces next photo, pop it up and prevent auto close
        shouldPopupOnVend = true
        shouldAutoClose = false
        photoVendor.vendImage(shouldRefresh: false)
    }

    func globalEventHandler(event: NSEvent) {
        close()
    }
}

// MARK: - PhotoVendorDelegate
extension PhotoFrameWindowController {
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
            if Settings.frame.autoCloseFrame && shouldAutoClose {
                autoCloseWorkItem?.cancel()  // cancel any pending auto close items
                // create new auto close work item
                autoCloseWorkItem = DispatchWorkItem { [weak self] in
                    log.verbose("Auto-closing")
                    self?.close()
                }

                // swiftlint:disable:next force_unwrapping
                DispatchQueue.main.asyncAfter(deadline: .now() + Settings.frame.autoCloseFrameAfter.timeInterval, execute: autoCloseWorkItem!)
            }

            shouldAutoClose = true  // reset auto close override, it's set in forceNext()
        } else if Settings.frame.newPhotoAction == .showNotification {
            showUserNotification(with: image)
        }

        // restart photo timers
        updatePhotoTiming(autoSwitchPhoto: Settings.photos.autoSwitchPhoto, autoSwitchPeriod: Settings.photos.autoSwitchPhotoPeriod)
    }

    func didFailToVend(error: Error?) {
        // TODO: implement this
        currentPhoto = NSImage(named: NSImage.everyoneName)!    // swiftlint:disable:this force_unwrapping
    }

    func showUserNotification(with image: NSImage) {
        // send notification
        let notification = NSUserNotification()
        notification.title = "New photo is ready!"
        notification.informativeText = "Click to see it."
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.contentImage = image
        NSUserNotificationCenter.default.deliver(notification)
    }

    func handleNotificationAction() {

    }
}

// MARK: - Window related methods
extension PhotoFrameWindowController: NSWindowDelegate {
    func show(relativeTo referenceWindow: NSWindow?) {
        guard let window = window else {
            log.error("Window is nil")
            return
        }
        // reset zoom, if any
        scrollView.magnification = 1

        self.referenceWindow = referenceWindow

        photoView.image = currentPhoto

        var newPhotoSize = windowSize - borderSize
        let newPhotoAspectRatio = currentPhoto.size.width / currentPhoto.size.height

        // determine photo view size based on max frame dimmension
        if currentPhoto.size.width > currentPhoto.size.height {
            // landscape (clamp width, calculate height)
            newPhotoSize.height = newPhotoSize.width / newPhotoAspectRatio
        } else {
            // portrait (clamp height, calculate width)
            newPhotoSize.width = newPhotoAspectRatio * newPhotoSize.height
        }

        photoView.frame = NSRect(origin: .zero, size: newPhotoSize)

        // new window size is photo size plus border
        windowSize = newPhotoSize + borderSize

        // set window position based on offset from reference window (which is usually status menu item)
        var windowOrigin = window.frame.origin
        if let referenceWindow = referenceWindow {
            windowOrigin = referenceWindow.frame.origin + windowOffset
            windowOrigin.y -= windowSize.height
        }

        // ensure that image is not off screen
        if let screenFrame = referenceWindow?.screen?.frame {
            windowOrigin.x = max(screenFrame.origin.x, windowOrigin.x)
            windowOrigin.y = max(screenFrame.origin.y, windowOrigin.y)
            windowOrigin.x = min(screenFrame.origin.x + screenFrame.size.width - windowSize.width, windowOrigin.x)
            windowOrigin.y = min(screenFrame.origin.y + screenFrame.size.height - windowSize.height, windowOrigin.y)
        }

        window.aspectRatio = windowSize + borderSize        // set aspect ratio to only allow diagonal resizing

        isAnimating = true

        // show window on top of everything
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        // start with frame at status icon and animate to desired location and size
        window.setFrame(animationStartFrame, display: true)
        window.alphaValue = 0

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.window?.animator().setFrame(NSRect(origin: windowOrigin, size: windowSize), display: true)
            self.window?.animator().alphaValue = 1
        }, completionHandler: {
            self.saveWindowPosition()
            self.isAnimating = false
        })

        // only install global event monitor if not already installed
        // any clicks outside the window will trigger frame to close
        if globalEventMonitor == nil {
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: globalEventHandler)
        }
    }

    override func close() {
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.window?.animator().setFrame(animationStartFrame, display: true)
            self.window?.animator().alphaValue = 0.0
        }, completionHandler: {
            super.close()
            self.isAnimating = false
        })

        status = (vendTimer?.isValid == true) ? .scheduled : .idle

        // remove the global event monitor when frame is closed
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            // clear out event monitor to indicate it's no longer installed
            self.globalEventMonitor = nil
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // size photoView to track window size with specified padding and maintain aspect ratio
        let aspectRatio = currentPhoto.size.width / currentPhoto.size.height
        var newPhotoSize = frameSize - borderSize
        // keep width as dragged, adjust height to match aspect ratio
        newPhotoSize.height = newPhotoSize.width / aspectRatio
        photoView.setFrameSize(newPhotoSize)

        // new window size is new photo size with border padding
        return newPhotoSize + borderSize
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        // only save window size if change is not result of animation
        guard let window = window, !isAnimating else { return }
        // save window size so the frame always opens with same size
        windowSize = window.frame.size
        print("Did end resize")
    }

    func windowDidMove(_ notification: Notification) {
        // only save position if window move is not result of animation
        if !isAnimating {
            saveWindowPosition()
        }
    }

    func saveWindowPosition() {
        // track offset of top left corner from origin so the frame always opens in the same location
        guard let window = window, let referenceWindow = referenceWindow else { return }
        windowOffset = window.frame.origin - referenceWindow.frame.origin
        windowOffset.y += window.frame.height
        print("Saving offset")
    }
}
