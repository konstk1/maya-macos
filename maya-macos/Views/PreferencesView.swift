//
//  PreferencesView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/12/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @State private var selectedTab = 1

    init() {
        log.info("Init prefs view")
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPrefsView().tabItem {
                // swiftlint-disable-next force_unwrapping
                Image(nsImage: NSImage(named: NSImage.preferencesGeneralName)!).frame(width: 40, height: 40)
                Text("General")
            }.tag(0)
            SourcesView().tabItem {
                Image(nsImage: #imageLiteral(resourceName: "SourcesIcon")).frame(width: 40, height: 40)
                Text("Sources")
            }.tag(1)
        }.frame(width: 500, height: 320)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView().environmentObject(PhotoVendor.shared)
    }
}
