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
    static let aboutWindowRequested = NSNotification.Name("aboutWindowRequested")
    static let tutorialWindowRequested = NSNotification.Name("tutorialWindowRequested")
}

enum PhotoFrameStatus {
    case idle
    case error
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

    // Other controllers
    private lazy var prefWinController = PrefsWindowController()
    private lazy var aboutController = AboutWindowController()
    private lazy var helpController = HelpWindowController()

    private(set) var nextPhotoAt: Date?

    // Photo vendor properties
    private let photoVendor = PhotoVendor.shared
    private var currentPhoto: NSImage = #imageLiteral(resourceName: "Maya Logo")
    private var vendTimer: Timer?

    // Photo frame properties
    @IBOutlet weak var titleBarView: NSView!
    @IBOutlet weak var timeLeftLabel: NSTextField!
    @IBOutlet weak var scrollView: PhotoScrollView!
    @IBOutlet weak var errorView: NSStackView!
    @IBOutlet weak var effectsView: NSVisualEffectView!

    // Error view outlets
    @IBOutlet weak var errorTitleLabel: NSTextField!
    @IBOutlet weak var errorSuggestedActionLabel: NSTextField!
    @IBOutlet weak var errorActionButton: NSButton!

    private var photoView: PhotoView!
    private var shouldPopupOnVend = false
    private var shouldAutoClose = true

    private let borderSize = NSSize(width: 10, height: 22+5)

    // Window properties
    // TODO: move this to Settings
    @PublishedUserDefault("PhotoFrame.photoDiagMax", defaultValue: 565.0 as CGFloat)  // roughly 400 x 400
    private var photoDiagMax

    /// Offset of the top left corner from the reference window specified in show(relativeTo:)
    @PublishedUserDefault("PhotoFrame.windowOffset", defaultValue: NSPoint(x: 0, y: -1))
    private var windowOffset

    weak var referenceWindow: NSWindow?
    private var globalEventMonitor: Any?

    var isVisible: Bool {
        return window?.isVisible ?? false
    }

    private var pendingAnimationCount = 0
    private var animationStartFrame: NSRect {
        if let frame = referenceWindow?.frame {
            return NSRect(x: frame.midX, y: frame.midY, width: borderSize.width, height: borderSize.height)
        } else {
            return NSRect(x: 0, y: 0, width: borderSize.width, height: borderSize.height)
        }
    }

    private var observers: [NSKeyValueObservation] = []
    private var subs: Set<AnyCancellable> = []

    private var autoCloseWorkItem: DispatchWorkItem?

    override var windowNibName: NSNib.Name? { NSNib.Name("PhotoFrameController") }

    private var lastTrialExpiredPopup = Date(timeIntervalSince1970: 0)

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
        photoVendor.$currentImage.compactMap { $0 }.receive(on: RunLoop.main).sink(receiveValue: didVendNewImage).store(in: &subs)

        photoVendor.$error.receive(on: RunLoop.main).sink(receiveValue: processError).store(in: &subs)

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

        let cornerRadius: CGFloat = 3

        effectsView.layer?.cornerRadius = cornerRadius + 1

        photoView = PhotoView()
        photoView.imageScaling = .scaleProportionallyUpOrDown

        scrollView.documentView = photoView
        scrollView.postsBoundsChangedNotifications = true
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = cornerRadius

//        window.isMovableByWindowBackground = true
        window.delegate = self

        let oneSecTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let isNarrow = self.titleBarView.frame.width > 200
            var text = "Auto switch off"

            if let timeUntil = self.nextPhotoAt?.timeIntervalSinceNow {
                text = (timeUntil > 0 ? timeUntil.labelString : "ready")
                if isNarrow {
                    text = "Next photo " + text
                }
            }

            self.timeLeftLabel.stringValue = text
        }
        RunLoop.main.add(oneSecTimer, forMode: .common)
    }

    override func mouseDown(with event: NSEvent) {
        log.verbose("Frame clicked, cancelling auto close...")
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
        nextPhotoAt = nil

        // set new timer based on settings
        if autoSwitchPhoto {
            log.info("Auto next photo in \(autoSwitchPeriod)")
            nextPhotoAt = Date(timeIntervalSinceNow: autoSwitchPeriod.timeInterval)
            vendTimer = Timer.scheduledTimer(withTimeInterval: autoSwitchPeriod.timeInterval, repeats: false, block: { [weak self] (_) in
                self?.shouldPopupOnVend = (Settings.frame.newPhotoAction == .popupFrame)
                self?.photoVendor.vendImage(shouldRefresh: true)
            })
        } else {
            log.info("Auto photo switch off")
        }

        // update status but don't override .newPhotoReady status, it'll be cleared when frame is closed
        if photoVendor.error != nil {
            status = .error
        } else if status != .newPhotoReady {
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
        // only close if corresponding setting is enabled
        if Settings.frame.closeByOutsideClick {
            close()
        }
    }

    // MARK: PhotoVendor handling
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

    func processError(error: Error?) {
        var showError = true

        var title: String
        var action: String

        switch error {
        case .some(PhotoVendorError.noActiveProvider):
            title = "No active photo source."
            action = "Configure photo sources in preferences."
        case .some(PhotoVendorError.noPhotos):
            title = "No images found"
            action = "Configure photo soures in preferences"
        case .some(PhotoVendorError.trialExpired):
            title = "Photo source trial expired"
            action = "Unlock this photo source in preferences"
             // limit popup to once every six hours
            if Date().timeIntervalSince(lastTrialExpiredPopup) > (6 * 3600) {
                show(relativeTo: referenceWindow)
                lastTrialExpiredPopup = Date()
            }
        case .some:
            title = "An error occurred"
            action = "Please ensure your photo sources are configured in preferences"
        case .none:
            title = ""
            action = ""
            showError = false
        }

        errorTitleLabel.stringValue = title
        errorSuggestedActionLabel.stringValue = action

        self.photoView.isHidden = showError
        self.errorView.isHidden = !showError

        status = showError ? .error : .newPhotoReady
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

    // MARK: @IBActions
    @IBAction func nextImageClicked(_ sender: NSButton) {
        forceNext()
    }

    @IBAction func aboutClicked(_ sender: NSMenuItem) {
        NotificationCenter.default.post(name: .aboutWindowRequested, object: nil)
    }

    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        close()
        NotificationCenter.default.post(name: .prefsWindowRequested, object: nil)
    }

    @IBAction func tutorialClicked(_ sender: NSMenuItem) {
        close()
        NotificationCenter.default.post(name: .tutorialWindowRequested, object: nil)
    }

    @IBAction func sendFeedbackClicked(_ sender: NSMenuItem) {
        sendFeedback()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
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

        // a = width / height
        // h^2 + w^2 = d^2
        // height = sqrt(d^2 / (1 + a^2))
        let newPhotoAspectRatio = currentPhoto.size.width / currentPhoto.size.height
        let height = sqrt(pow(photoDiagMax, 2) / (1 + pow(newPhotoAspectRatio, 2)))
        let width = height * newPhotoAspectRatio
        let newPhotoSize = NSSize(width: width, height: height)

        photoView.frame = NSRect(origin: .zero, size: newPhotoSize)

        // new window size is photo size plus border
        let windowSize = newPhotoSize + borderSize

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

        // makeKeyAndOrderFront() will trigger window move/resize events, where we save window position
        // since at this point the frame will be animating, we want to ignore those events and only
        // take action when there are no pending animations
        pendingAnimationCount += 1

        // we'll want to skip animating from menu bar icon if the window is already visible (user likely hit next)
        // in this case, we'll just animate from current to new size
        if !window.isVisible {
            // start with frame at status icon and animate to desired location and size
            window.setFrame(animationStartFrame, display: true)
            window.alphaValue = 0
        }

        // show window on top of everything
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.level = .statusBar       // always keep on top

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.window?.animator().setFrame(NSRect(origin: windowOrigin, size: windowSize), display: true)
            self.window?.animator().alphaValue = 1
        }, completionHandler: {
            self.saveWindowPosition()
            self.pendingAnimationCount = max(self.pendingAnimationCount - 1, 0) // don't let go below zero
        })

        // only install global event monitor if not already installed
        // any clicks outside the window will trigger frame to close
        if globalEventMonitor == nil {
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: globalEventHandler)
        }
    }

    override func close() {
        // super.close() will trigger window move/resize events, where we save window position
        // since at this point the frame will be animating, we want to ignore those events and only
        // take action when there are no pending animations
        pendingAnimationCount += 1
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.window?.animator().setFrame(animationStartFrame, display: true)
            self.window?.animator().alphaValue = 0.0
        }, completionHandler: {
            super.close()
            self.pendingAnimationCount = max(self.pendingAnimationCount - 1, 0) // don't let go below zero
        })

        if photoVendor.error != nil {
            status = .error
        } else {
            status = (vendTimer?.isValid == true) ? .scheduled : .idle
        }

        // remove the global event monitor when frame is closed
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            // clear out event monitor to indicate it's no longer installed
            self.globalEventMonitor = nil
        }

        // request app store review (this function will apply constraints when the review is actually requested)
        requestAppStoreReview()
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
        if pendingAnimationCount == 0 {
            // save image daigonal so the frame always opens with same size
            photoDiagMax = sqrt(pow(photoView.frame.width, 2) + pow(photoView.frame.height, 2))
            saveWindowPosition()
//            print("Did end resize diag: \(photoDiagMax)")
        }
    }

    func windowDidMove(_ notification: Notification) {
        // only save position if window move is not result of animation
        if pendingAnimationCount == 0 {
            saveWindowPosition()
        }
    }

    func saveWindowPosition() {
        // track offset of top left corner from origin so the frame always opens in the same location
        guard let window = window, let referenceWindow = referenceWindow else { return }
        windowOffset = window.frame.origin - referenceWindow.frame.origin
        windowOffset.y += window.frame.height
//        print("Saving offset \(windowOffset)")
    }
}
