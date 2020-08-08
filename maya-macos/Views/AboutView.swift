//
//  AboutView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/11/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI
import SwiftyBeaver

// swiftlint:disable multiple_closures_with_trailing_closure

struct AboutView: View {
    var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }

    private let website: String = "https://konst.dev/maya"

    @State private var showLogButton = false

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Image(nsImage: NSImage.mayaLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)

                VStack(alignment: .center, spacing: 10) {
                    Text("Maya Frame").font(.custom("San Francisco", size: 20))
                    Text("Version \(appVersion)").font(.system(size: 10))
                }
            }

            VStack(spacing: 10) {
                Button(action: {
                    sendFeedback()
                }) {
                    Text("Send feedback").frame(width: 150, height: 30)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.helpText))
                        .contentShape(Rectangle())
                }
                if showLogButton {
                    Button(action: {
                        self.revealLogFileInFinder()
                    }) {
                        Text("Reveal log file").frame(width: 150, height: 20)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.helpText))
                            .contentShape(Rectangle())
                    }
                }
            }.buttonStyle(PlainButtonStyle()).padding(20)

            HStack {
                Text("Website:").bold()
                Button(action: {
                    let url = URL(string: self.website)!  // swiftlint:disable:this force_unwrapping
                    NSWorkspace.shared.open(url)
                }) {
                    Text(self.website).underline().foregroundColor(.blue)
                        .onHover { isHovering in
                            if isHovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }.buttonStyle(PlainButtonStyle())
            }

            Text("Copyright © 2020 Konstantin Klitenik. All rights reserved.")
                .font(.custom("San Francisco", size: 10))
                .padding(.top, 10)
        }.padding(25).fixedSize().background(Color.aboutBackground).foregroundColor(Color.helpText)
            .gesture(TapGesture().modifiers(.command).onEnded { _ in
                self.showLogButton = true
            })
    }

    func revealLogFileInFinder() {
        let fileDestinations = log.destinations.compactMap { $0 as? FileDestination }

        if let logFileUrl = fileDestinations.first?.logFileURL {
            NSWorkspace.shared.selectFile(logFileUrl.path, inFileViewerRootedAtPath: "")
        } else {
            log.error("No log file exists")
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AboutView().environment(\.colorScheme, .light)
            AboutView().environment(\.colorScheme, .dark)
        }
    }
}
