//
//  AboutView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/11/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI
import SwiftyBeaver

struct AboutView: View {
    var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }
    
    @State private var logButtonTitle = "Copy Log Path"
    
    var body: some View {
        VStack {
            HStack {
                Image(nsImage: NSImage(named: NSImage.everyoneName)!).resizable().aspectRatio(contentMode: ContentMode.fit).frame(width: 100, height: 100)
                Spacer().frame(width: 30)
                VStack(alignment: .leading) {
                    Text("Maya").font(.system(size: 25))
                    Text("Version \(appVersion)")
                }
            }
            Text("Copyright © 2019 Konstantin Klitenik")
            Button(logButtonTitle) {
                self.copyLogPathClicked()
            }
        }.padding().fixedSize().onAppear {
            self.logButtonTitle = "Copy Log Path"
            print("On appear")
        }.onDisappear() {
            print("On disappear")
        }
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
        AboutView()
    }
}
