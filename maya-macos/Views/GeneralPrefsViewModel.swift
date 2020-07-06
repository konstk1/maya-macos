//
//  GeneralPrefsViewModel.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class GeneralPrefsViewModel: ObservableObject {
    @Published var appSettings = Settings.app
    @Published var frameSettings = Settings.frame
    @Published var photoSettings = Settings.photos {
        didSet {
            autoSwitchPeriodString = String(photoSettings.autoSwitchPhotoPeriod.value)
        }
    }

    @Published var autoSwitchPeriodString: String {
        didSet {
            guard var value = NumberFormatter().number(from: autoSwitchPeriodString) as? Int else {
                autoSwitchPeriodString = String(photoSettings.autoSwitchPhotoPeriod.value)
                return
            }

            // don't allow 0 value, clamp it to 1
            if value == 0 {
                value = 1
                autoSwitchPeriodString = "1"
            }

            self.photoSettings.autoSwitchPhotoPeriod.value = value
        }
    }

//    lazy var autoSwithPeriodBinding = Binding<String>(get: {
//        String(self.photoSettings.autoSwitchPhotoPeriod.value)
//    }, set: { str in
//        print("New str: \(str)")
//        guard let value = NumberFormatter().number(from: str) as? Int else { return }
//        print("New val: \(value)")
//
//        self.photoSettings.autoSwitchPhotoPeriod.value = value
//    })

    let newPhotoActions = NewPhotoAction.allCases.map { (action) -> String in
         switch action {
         case .updateIcon: return "update icon"
         case .showNotification: return "show notificaiton"
         case .popupFrame: return "pop it up"
         }
     }

    @Published var newPhotoActionsSelection = NewPhotoAction.allCases.firstIndex(of: Settings.frame.newPhotoAction) ?? 0 {
        didSet {
            frameSettings.newPhotoAction = NewPhotoAction.allCases[newPhotoActionsSelection]
            log.info("Updated photo action \(newPhotoActionsSelection) - \(frameSettings.newPhotoAction)")
        }
    }

    static let autoCloseTimeOptions: [TimePeriod] = [.seconds(5), .seconds(10), .seconds(15), .seconds(30), .seconds(60)]

    @Published var autoCloseTimeSelection = autoCloseTimeOptions.firstIndex(of: Settings.frame.autoCloseFrameAfter) ?? 0 {
        didSet {
            frameSettings.autoCloseFrameAfter = Self.autoCloseTimeOptions[autoCloseTimeSelection]
            log.info("Updated auto close time (\(autoCloseTimeSelection)): \(frameSettings.autoCloseFrameAfter)")
        }
    }

    static let autoSwitchUnitsOptions = TimeUnit.allCases.map { $0.rawValue }

    @Published var autoSwitchUnitSelection = autoSwitchUnitsOptions.firstIndex(of: Settings.photos.autoSwitchPhotoPeriod.unit.rawValue) ?? 0 {
        didSet {
            photoSettings.autoSwitchPhotoPeriod.unit = TimeUnit.allCases[autoSwitchUnitSelection]
            log.info("Updated auto switch period \(autoSwitchUnitSelection): \(photoSettings.autoSwitchPhotoPeriod)")
        }
    }

    init() {
        autoSwitchPeriodString = String(Settings.photos.autoSwitchPhotoPeriod.value)
    }
}
