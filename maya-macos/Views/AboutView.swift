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

    @State private var logButtonTitle = "Copy Log Path"

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

            #if !DEBUG
            Button(logButtonTitle) {
                self.copyLogPathClicked()
            }
            #endif

            VStack {
                Button(action: {
                    sendFeedback()
                }) {
                    Text("Send feedback").frame(width: 120, height: 30)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.helpText))
                        .contentShape(Rectangle())
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
        }.padding(25).fixedSize().onAppear {
            self.logButtonTitle = "Copy Log Path"
            print("On appear")
        }.onDisappear {
            print("On disappear")
        }.background(Color.aboutBackground).foregroundColor(Color.helpText)
    }

    func copyLogPathClicked() {
        let pasteBoard = NSPasteboard.general
        pasteBoard.declareTypes([.string], owner: nil)

        let fileDestinations = log.destinations.compactMap { $0 as? FileDestination }

        var status = "Copied!"

        if let logFilePath = fileDestinations.first?.logFileURL?.path {
            if !pasteBoard.setString(logFilePath, forType: .string) {
                status = "Copy Failed!"
            }
        } else {
            status = "No log file!"
        }

        logButtonTitle = status
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
