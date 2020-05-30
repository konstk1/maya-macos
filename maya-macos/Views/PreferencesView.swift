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
    @State private var selectedTab = 0

    let iconSize: CGFloat = 30

    init() {
        log.info("Init prefs view")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tabs
            HStack(spacing: 0) {
                Button(action: {
                    self.selectedTab = 0
                }) {
                    VStack(spacing: 0) {
                        Image(nsImage: NSImage(named: NSImage.preferencesGeneralName)!).frame(width: self.iconSize, height: self.iconSize).padding(5)
                        Text("General").font(.caption).padding([.horizontal, .bottom], 4)
                    }
                    }.buttonStyle(PlainButtonStyle())
                    .background(RoundedRectangle(cornerRadius: 5).fill(self.selectedTab == 0 ? Color(red: 0.76, green: 0.76, blue: 0.76) : Color.clear))

                Button(action: {
                    self.selectedTab = 1
                }) {
                    VStack(spacing: 0) {
                        Image(nsImage: #imageLiteral(resourceName: "SourcesIcon")).resizable().scaledToFit().frame(width: self.iconSize, height: self.iconSize).padding(5)
                        Text("Sources").font(.caption).padding([.horizontal, .bottom], 4)
                    }
                }.buttonStyle(PlainButtonStyle())
                    .background(RoundedRectangle(cornerRadius: 5).fill(self.selectedTab == 1 ? Color(red: 0.76, green: 0.76, blue: 0.76) : Color.clear))
                Spacer()
            }.padding([.leading, .top], 5)
                .background(Color(red: 0.85, green: 0.85, blue: 0.85))

            Divider()

            Group {
                if selectedTab == 0 {
                    GeneralPrefsView()
                } else {
                    SourcesView()
                }
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView().environmentObject(PhotoVendor.shared)
    }
}
