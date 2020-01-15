//
//  GeneralPrefsViewModel.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation

class GeneralPrefsViewModel: ObservableObject {
    @Published var appSettings = Settings.app
    @Published var frameSettings = Settings.frame
    @Published var photoSettings = Settings.photos
    
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
            print("Updated photo action \(newPhotoActionsSelection) - \(frameSettings.newPhotoAction)")
        }
    }
    
    static let autoCloseTimeOptions: [TimePeriod] = [.seconds(5), .seconds(10), .seconds(15), .seconds(30), .seconds(60)]
    
    @Published var autoCloseTimeSelection = autoCloseTimeOptions.firstIndex(of: Settings.frame.autoCloseFrameAfter) ?? 0 {
        didSet {
            frameSettings.autoCloseFrameAfter = Self.autoCloseTimeOptions[autoCloseTimeSelection]
            print("Updated auto close time (\(autoCloseTimeSelection)): \(frameSettings.autoCloseFrameAfter)")
        }
    }
    
    static let autoSwitchUnitsOptions = TimeUnit.allCases.map { $0.rawValue }
    
    @Published var autoSwitchUnitSelection = autoSwitchUnitsOptions.firstIndex(of: Settings.photos.autoSwitchPhotoPeriod.unit.rawValue) ?? 0 {
        didSet {
            photoSettings.autoSwitchPhotoPeriod.unit = TimeUnit.allCases[autoSwitchUnitSelection]
            print("Updated auto switch period \(autoSwitchUnitSelection): \(photoSettings.autoSwitchPhotoPeriod)")
        }
    }
    
    init() {
    }
}
