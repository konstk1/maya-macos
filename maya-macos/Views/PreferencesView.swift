//
//  PreferencesView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/12/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralPrefsView().tabItem {
                Image(nsImage: NSImage(named: NSImage.preferencesGeneralName)!)
                Text("General")
            }.tag(0)
            Text("Sources").tabItem {
                Image(nsImage: NSImage(named: "SourcesIcon")!)
                Text("Sources")
            }.tag(0)
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
