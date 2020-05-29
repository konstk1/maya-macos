//
//  SourcesViewController.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/11/19.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa

class SourcesViewController: NSViewController {
    private let photoVendor = PhotoVendor.shared

    private var indexOfActiveProvider: Int {
        photoVendor.photoProviders.firstIndex { $0 === photoVendor.activeProvider } ?? 0
    }

    @IBOutlet var localFolderVC: LocalFolderProviderViewController!
    @IBOutlet var googlePhotosVC: GooglePhotosViewController!

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var sourceView: NSView!

    private var currentSourceController: NSViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        selectViewControllerAt(index: indexOfActiveProvider)

        NotificationCenter.default.addObserver(self, selector: #selector(updatePhotoCount(_:)), name: .updatePhotoCount, object: nil)
    }

    @objc func updatePhotoCount(_ notification: Notification) {
        guard let notifyingProvider = notification.object as? PhotoProvider else { return }

        log.debug("Update photo count notification \(notifyingProvider)")

        let row: Int

        switch notifyingProvider {
        case is LocalFolderPhotoProvider:
            row = 0
        case is GooglePhotoProvider:
            row = 1
        default:
            log.error("Unsupported photo provider \(notifyingProvider.self)")
            return
        }

        tableView.reloadData(forRowIndexes: [row], columnIndexes: [0])
    }

    func selectViewControllerAt(index: Int) {
        // remove current view controller, if any
        if let currentSourceController = currentSourceController {
            currentSourceController.removeFromParent()
            currentSourceController.view.removeFromSuperview()
        }

        // add new view controller
        switch photoVendor.photoProviders[index] {
        case is LocalFolderPhotoProvider:
            // load local folder controller
            currentSourceController = localFolderVC
        case is GooglePhotoProvider:
            currentSourceController = googlePhotosVC
        default:
            log.error("Unimplement view for provider")
            fatalError("Inimplement provider")
        }

        // swiftlint:disable force_unwrapping
        self.addChild(currentSourceController!)
        currentSourceController!.view.frame = NSRect(x: 0, y: 0, width: sourceView.frame.width, height: sourceView.frame.height)
        sourceView.addSubview(currentSourceController!.view)
        // swiftlint:enable force_unwrapping
    }

    @IBAction func activateClicked(_ sender: NSButton) {
        let previouslyActiveRow = indexOfActiveProvider
        let newActiveRow = tableView.row(for: sender)

        let provider = PhotoVendor.shared.photoProviders[newActiveRow]

        log.info("Activating \(provider.self)")

        PhotoVendor.shared.setActiveProvider(provider)

        // persist active provider to Settings
        var providerType: PhotoProviderType

        switch provider {
        case is LocalFolderPhotoProvider:
            providerType = .localFolder
        case is GooglePhotoProvider:
            providerType = .googlePhotos
        case is ApplePhotoProvider:
            providerType = .applePhotos
        default:
            providerType = .none
            log.warning("Unimplemented photo provider type")
        }

        Settings.app.activeProvider = providerType

        // reload rows affected by the change (prev.active, active) and select new active row
        let rowsToReload = [previouslyActiveRow, newActiveRow].compactMap { $0 }
        tableView.reloadData(forRowIndexes: IndexSet(rowsToReload), columnIndexes: [0])
        tableView.selectRowIndexes([newActiveRow], byExtendingSelection: false)
    }
}

extension SourcesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return PhotoVendor.shared.photoProviders.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SourceCell"), owner: nil) as? SourceCell else { return nil }

        let provider = photoVendor.photoProviders[row]

        var providerName: String
        var iconImage: NSImage

        switch provider {
        case is LocalFolderPhotoProvider:
            providerName = "Local Folder"
            iconImage = NSImage(named: NSImage.folderName)!     // swiftlint:disable:this force_unwrapping
        case is GooglePhotoProvider:
            providerName = "Google Photos"
            iconImage = #imageLiteral(resourceName: "GooglePhotos")
        default:
            providerName = "Unknown"
            iconImage = NSImage(named: NSImage.everyoneName)!   // swiftlint:disable:this force_unwrapping
        }

        cell.titleLabel.stringValue = providerName
        cell.iconView.image = iconImage

        cell.photoCountLabel.title = String(provider.photoDescriptors.count)

        // configure activate radio button
        var isActive = false
        if let activeProvider = PhotoVendor.shared.activeProvider {
            isActive = (provider === activeProvider)
        }
        cell.activateButton.state = isActive ? .on : .off
        cell.activateButton.action = #selector(activateClicked(_:))
        cell.activateButton.target = self

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView, tableView.selectedRow >= 0 else {
                return
        }

        selectViewControllerAt(index: tableView.selectedRow)
    }
}
