//
//  PreferencesView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/12/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPrefsView().tabItem {
                Image(nsImage: NSImage(named: NSImage.preferencesGeneralName)!).frame(width: 40, height: 40)
                Text("General")
            }
            SourcesView().tabItem {
                Image(nsImage: NSImage(named: "SourcesIcon")!).frame(width: 40, height: 40)
                Text("Sources")
            }
            Image(nsImage: NSImage(named: "SourcesIcon")!).frame(width: 40, height: 40).tabItem {
                Text("Image")
            }
        }.frame(width: 500, height: 320).padding()
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
