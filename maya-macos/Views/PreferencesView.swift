//
//  PreferencesView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/12/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

// swiftlint:disable multiple_closures_with_trailing_closure

struct PreferencesView: View {
    @State private var selectedTab = Tabs.general

    enum Tabs {
        case general
        case sources
    }

    let iconSize: CGFloat = 30

    init() {
        log.info("Init prefs view")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tabs
            HStack(spacing: 0) {
                Button(action: {
                       self.selectedTab = .general
                }) {
                    VStack(spacing: 0) {
                        Image(nsImage: NSImage(named: NSImage.preferencesGeneralName)!).frame(width: self.iconSize, height: self.iconSize).padding(5)
                        Text("General").font(.caption).padding([.horizontal, .bottom], 4)
                    }.contentShape(Rectangle())
                    }.buttonStyle(PlainButtonStyle())
                    .background(RoundedRectangle(cornerRadius: 5).fill(self.selectedTab == .general ? Color.tabBarSelected : Color.clear))

                Button(action: {
                    self.selectedTab = .sources
                }) {
                    VStack(spacing: 0) {
                        Image(nsImage: #imageLiteral(resourceName: "SourcesIcon")).resizable().scaledToFit().frame(width: self.iconSize, height: self.iconSize).padding(5)
                        Text("Sources").font(.caption).padding([.horizontal, .bottom], 4)
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
                    .background(RoundedRectangle(cornerRadius: 5).fill(self.selectedTab == .sources ? Color.tabBarSelected : Color.clear))

                Spacer()    // fill the rest of horizontal space
            }
            .padding([.leading, .top], 5)
            .background(Color.tabBarBackground)
            .frame(width: selectedTab == .general ? 460 : 580)
//            Divider()

            Group {
                if selectedTab == .general {
                    GeneralPrefsView()
                } else if selectedTab == .sources {
                    SourcesView()
                }
            }
        }.background(Color.prefsBackground)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView().environmentObject(PhotoVendor.shared)
    }
}
