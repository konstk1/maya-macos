//
//  HelpView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/1/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

// swiftlint:disable multiple_closures_with_trailing_closure

struct HelpView: View {
    @State var currentPage = 0
    private let numPages = 3
    @State private var navDirection = NavDirection.none

    enum NavDirection {
        case none, forward, back
    }

    private let pageTitles = [ "Welcome to Maya Frame", "Photo Sources", "Navigating the Photo Frame"]
    private let imageTitles = ["Screen1", "Screen2", "Screen2"]

    var body: some View {
        VStack {
            VStack(spacing: 25) {
                // Header
                HStack {
                    Spacer()
                    Image(nsImage: .mayaLogo).resizable().scaledToFit().frame(width: 50).offset(y: -3)
                    Text(pageTitles[currentPage])
                        .font(.custom("San Francisco", size: 24))
//                        .bold()
                        .foregroundColor(.helpText)
                    Spacer()
                }.padding(.top, 20)
                Image(imageTitles[currentPage]).resizable().scaledToFit().frame(height: 250).shadow(radius: 15, x: 2, y: 7)
                helpBody(for: currentPage).padding(EdgeInsets(top: 5, leading: 30, bottom: 0, trailing: 0))
                    .foregroundColor(.helpText)
                    //            .font(.custom("San Francisco", size: 16))
                    //            .font(.system(size: 16, weight: .regular, design: .default))
                    .font(.system(size: 14))
//                    .border(Color.gray)
                Spacer()
            }.frame(width: 550, height: 585).id(currentPage)  // supply ID so whole page is transitioned
                .padding()
                .transition(.asymmetric(
                    insertion: .move(edge: self.navDirection == .forward ? .trailing : .leading),
                    removal: .move(edge: self.navDirection == .forward ? .leading : .trailing)))
                .animation(self.navDirection == .none ? nil : .easeInOut)

            // Footer
            HStack {
                if currentPage > 0 {
                    Button(action: {
                        guard self.currentPage > 0 else { return }
                        self.navDirection = .back
                        withAnimation(.easeInOut) {
                            self.currentPage -= 1
                        }
                    }) {
                        Text("Previous").foregroundColor(Color.helpText)
                            .frame(width: 100, height: 30)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.helpText))
                            .contentShape(Rectangle())
                    }.buttonStyle(PlainButtonStyle())
                }
                Spacer()
                if currentPage < (numPages - 1) {
                    Button(action: {
                        guard self.currentPage < self.numPages - 1 else { return }
                        self.navDirection = .forward
                        withAnimation(.easeInOut) {
                            self.currentPage += 1
                            if self.currentPage == self.numPages {
                                self.currentPage = 0
                            }
                        }
                    }) {
                        Text("Next").bold().foregroundColor(Color.helpText)
                            .frame(width: 100, height: 30)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.helpText))
                            .contentShape(Rectangle())
                    }.buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        NSApplication.shared.keyWindow?.close()
                        NotificationCenter.default.post(name: .prefsWindowRequested, object: nil)
                    }) {
                        Text("Continue to Preferences").bold().foregroundColor(Color.white)
                            .frame(width: 180, height: 30)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.mayaBlue))
//                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.helpText))
                    }.buttonStyle(PlainButtonStyle())
                }
            }.padding(.horizontal, 30)
            Divider().padding(.top, 10)
            HStack {
                Spacer()
                CaruselDots(numDots: numPages, activeIndex: $currentPage).padding()
                Spacer()
            }.background(Color(red: 0.9, green: 0.9, blue: 0.9)).padding(.top, -10)
        }.background(Color.aboutBackground)
    }

    func helpBody(for page: Int) -> some View {
        return Group {
            if currentPage == 0 {
                pageOneText
            } else if currentPage == 1 {
                pageTwoText
            } else {
                pageThreeText
            }
        }
    }

    var pageOneText: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Maya Frame works like a digital photo frame in your Mac's status bar. There are several settings to configure so be sure to check out the ") + Text("Preferences.").bold()
            Text("Click on the ") + Text("status icon").italic() + Text(" any time to view the photo.")
            Text("The ") + Text("status icon").italic() + Text(" reflects the current state:")
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image("StatusIcon-All")
                    Text("New photo is ready")
                }
                HStack {
                    Image("StatusIcon-Green")
                    Text("Auto-switch photo is on, next photo is scheduled")
                }
                HStack {
                    Image("StatusIcon-Red")
                    Text("Error occured")
                }
                HStack {
                    Image("StatusIcon-None")
                    Text("Auto-switch photo is off")
                }
            }.padding(.leading, 50)
        }
    }

    var pageTwoText: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("You can set your photo sources under the ") + Text("Sources").bold() + Text(" tab in ") + Text("Preferences.").bold()
            Text("Currently, ") + Text("Local Folder").italic() + Text(" and ") + Text("Apple Photos").italic() + Text(" are available. More sources are coming soon.")
            Text("To enable currently selected source, click the ") + Text("Activate").bold() + Text(" button.")
        }
    }

    var pageThreeText: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Double click").italic() + Text(" on or ") + Text("pinch").italic() + Text(" the photo to zoom in & out.")
            Text("Drag").italic() + Text(" or ") + Text("two-finger pan").italic() + Text(" to move around ") + Text("zoomed in").italic() + Text(" image.")
            Text("Drag sides").italic() + Text(" of the frame to resize.")
            Text("Drag zoomed out image").italic() + Text(" to move the frame.")
        }
    }
}

struct CaruselDots: View {
    var numDots: Int
    @Binding var activeIndex: Int

    let radius: CGFloat = 10
    let spacing: CGFloat = 15

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: self.spacing) {
                ForEach(0..<numDots) { _ in
                    Circle().frame(width: self.radius, height: self.radius).foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                }
            }
            Circle().frame(width: self.radius, height: self.radius).foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)).offset(x: CGFloat(self.activeIndex) * (self.spacing + self.radius))
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HelpView()
        }
    }
}
