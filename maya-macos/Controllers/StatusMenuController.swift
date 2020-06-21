//
//  StatusMenuController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa
import Combine

class StatusMenuController: NSObject, NSUserNotificationCenterDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private var photoFrame = PhotoFrameWindowController()
    private lazy var prefWinController = PrefsWindowController()
    private lazy var aboutController = AboutWindowController()
    private lazy var helpController = HelpWindowController()

    private let mouseEventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]

    private var subs: Set<AnyCancellable> = []

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var timeLeftLabel: NSMenuItem!

    override func awakeFromNib() {
        setIcon()
        statusItem.menu = statusMenu

        NSEvent.addLocalMonitorForEvents(matching: mouseEventMask, handler: localEventHandler)

        NotificationCenter.default.publisher(for: .photoFrameStatus).receive(on: RunLoop.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.setIcon()
        }.store(in: &subs)

        NotificationCenter.default.publisher(for: .prefsWindowRequested).sink { [weak self] _ in
            self?.preferencesClicked(NSMenuItem())
        }.store(in: &subs)

        NSUserNotificationCenter.default.delegate = self

        let oneSecTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let timeUntil = self.photoFrame.nextPhotoAt?.timeIntervalSinceNow {
                self.timeLeftLabel.title = "Next photo " + (timeUntil > 0 ? "in " + timeUntil.labelString : "ready")
            } else {
                self.timeLeftLabel.title = "Auto switch off"
            }
        }
        RunLoop.main.add(oneSecTimer, forMode: .common)
    }

    func setIcon() {
        var icon: NSImage?
        switch photoFrame.status {
        case .idle:
            icon = #imageLiteral(resourceName: "StatusIcon-None")
        case .error:
            icon = #imageLiteral(resourceName: "StatusIcon-Red")
        case .scheduled:
            icon = #imageLiteral(resourceName: "StatusIcon-Green")
        case .newPhotoReady:
            icon = #imageLiteral(resourceName: "StatusIcon-All")
        }

        if let icon = icon {
            statusItem.button?.image = icon
        } else {
            statusItem.button?.image = nil
            statusItem.button?.title = "Maya"
        }
    }

    func localEventHandler(event: NSEvent) -> NSEvent? {
        // if we get a local left click in the status item button, toggle the popover
        // and block left click from being propagated
        // if the click is out the photo frame, close the popover and propagate the event
        // otherwise, do nothing and simply propagate the event

        /// indicates if intercepted event should be propagaged
        var blockEvent = false

        // if user is holding cmd key, then they're trying to move the status bar item
        // don't do anything and just propagate the event
        let isMoveEvent = event.modifierFlags.contains(NSEvent.ModifierFlags.command)

        // close popover if clicked on status item or outside the photo frame
        // don't close and forward event if clicked inside photo frame window
        if event.type == .leftMouseDown && !isMoveEvent {
//            print("Event screen \(event.window?.screen?.frame)")
//            print("Button screen \(statusItem.button?.window?.frame)")
            if event.window == statusItem.button?.window {
                togglePopover()
                blockEvent = true    // don't propagate this event any further
            } else if event.window != photoFrame.window && photoFrame.isVisible {
                closePopover()
            }
        }

        return blockEvent ? nil : event
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        photoFrame.show(relativeTo: statusItem.button?.window)
        center.removeAllDeliveredNotifications()
    }

    func togglePopover() {
        if photoFrame.isVisible == true {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        photoFrame.show(relativeTo: statusItem.button?.window)
    }

    func closePopover() {
        photoFrame.close()
    }

    @IBAction func cantWaitClicked(_ sender: Any) {
        photoFrame.forceNext()
    }

    @IBAction func aboutClicked(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        aboutController.showWindow(sender)
    }

    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        prefWinController.showWindow(sender)
    }

    @IBAction func tutorialClicked(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        helpController.showWindow(sender)
    }

    @IBAction func sendFeedbackClicked(_ sender: NSMenuItem) {
        sendFeedback()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}
