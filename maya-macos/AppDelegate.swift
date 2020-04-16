//
//  AppDelegate.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/19/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import ServiceManagement
import OAuthSwift
import SwiftyBeaver

let log: SwiftyBeaver.Type = {
    let log = SwiftyBeaver.self
    let console = ConsoleDestination()
    console.levelColor.verbose = "◻️ "
    console.levelColor.debug   = "◼️ "
    console.levelColor.info    = "🔷 "
    console.levelColor.warning = "🔶 "
    console.levelColor.error   = "🛑 "
    
    log.addDestination(console)
    
    let logDirectoryURL = try? FileManager.default.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask, appropriateFor: nil, create: true)
    
    let file = FileDestination()
    file.logFileURL = logDirectoryURL?.appendingPathComponent("maya.log")
    log.addDestination(file)
    
    log.verbose("Log file: \(file.logFileURL?.path ?? "none")")
    log.verbose("SwiftyBeaver ready")
    return log
}()

let launcherAppId = "com.kk.maya-macos-launcher"

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == launcherAppId }
        
        #if DEBUG
        // Don't start rest of the app if running unit tests
        let isUnitTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        guard !isUnitTesting else {
            log.warning("Unit testing... skipping main app.")
            return
        }
        #endif
        
        SMLoginItemSetEnabled(launcherAppId as CFString, Settings.app.openAtLogin)
        
        // if launcher is running, send notification to terminate it
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
        
        // register to handle URL scheme
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleGetURL(event:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }
    
    /// URL event handler to pass callbacks to OAuth
    @objc func handleGetURL(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
//        log.debug("Handle URL: \(event)")
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue, let url = URL(string: urlString) {
            log.debug("URL: \(urlString)")
            OAuthSwift.handle(url: url)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }

    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "maya_macos")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
//    // MARK: - Core Data stack w/ CloudKit
//
//    lazy var persistentContainer: NSPersistentCloudKitContainer = {
//        /*
//         The persistent container for the application. This implementation
//         creates and returns a container, having loaded the store for the
//         application to it. This property is optional since there are legitimate
//         error conditions that could cause the creation of the store to fail.
//        */
//        let container = NSPersistentCloudKitContainer(name: "maya_macos")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Unresolved error \(error)")
//            }
//        })
//        return container
//    }()
//
    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }

        if !context.hasChanges {
            return .terminateNow
        }

        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }

            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)

            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
}

