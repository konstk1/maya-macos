//
//  AppDelegate.swift
//  maya-macos-launcher
//
//  Created by Konstantin Klitenik on 7/31/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppIdentifier = "com.kk.maya-macos"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == mainAppIdentifier }

        // ensure that main app is not already running, otherwise terminate the launcher
        guard !isRunning else {
            terminate()
            return
        }

        DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name: .killLauncher, object: mainAppIdentifier)

        let path = Bundle.main.bundlePath as NSString
        var components = path.pathComponents
        components.removeLast(3)
        components.append("MacOS")
        components.append("Maya")

        let mainAppPath = NSString.path(withComponents: components)

        NSWorkspace.shared.launchApplication(mainAppPath)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}
