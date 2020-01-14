//
//  GeneralPrefsView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/12/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct GeneralPrefsView: View {
    @State private var openAtLogin = false
    
    @State private var selection = 0
    
    @State private var autoClose = false
    @State private var autoCloseTimeSelection = 0
    
    @State private var autoSwitchPhotos = false
    @State private var autoSwitchPeriod = 15
    @State private var autoSwitchPeriodStr = ""
    @State private var autoSwitchUnitSelection = 0
    
    @ObservedObject private var frameSettings = Settings.frame
    private var autoCloseTest = Settings.frame.$autoCloseFrame
    
    struct HintText: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 20) {
                Text("Startup:").frame(width: 70, alignment: .trailing)
                VStack(alignment: .leading) {
                    Toggle(isOn: $openAtLogin) {
                        Text("Open Maya at login")
                    }
                    Text("Start Maya automatically at login.").modifier(HintText())
                }
            }
            Divider().frame(width: 400)
            HStack(alignment: .top, spacing: 20) {
                Text("Frame:").frame(width: 70, alignment: .trailing)
                VStack(alignment: .leading) {
                    Picker(selection: $selection, label:
                    Text("When new photos is ready").fixedSize(horizontal: true, vertical: false)) {
                        Text("one").tag(0)
//                        Text("two").tag(1)
                    }.frame(width: 260)
                    Text("Action to take when new photo is ready.").modifier(HintText())
                    
                    HStack {
                        Toggle(isOn: $frameSettings.autoCloseFrame) {
                            Text("Automatically close after")
                        }.onReceive(frameSettings.$autoCloseFrame) { (output) in
                            print("Auto close \(self.frameSettings.autoCloseFrame)")
                        }
                        Picker("", selection: $autoCloseTimeSelection) {
                            Text("one").tag(0)
                            Text("two").tag(1)
                        }.frame(width: 70).padding(.leading, -7)
                    }
                    Text("Photo frame will automatically close after this specified period.").modifier(HintText())
                }
            }
            Divider().frame(width: 400)
            HStack(alignment: .top, spacing: 20) {
                Text("Photos:").frame(width: 70, alignment: .trailing)
                VStack(alignment: .leading) {
                    HStack {
                        Toggle(isOn: $autoSwitchPhotos) {
                            Text("Switch photos every").fixedSize()
                        }
                        
                        Stepper(value: $autoSwitchPeriod) {
                            TextField("", value: $autoSwitchPeriod, formatter: NumberFormatter())
                                .multilineTextAlignment(.trailing)
                                .padding(.trailing, -5)
                        }.frame(width: 50)
                        Picker("", selection: $autoSwitchUnitSelection) {
                            Text("one").tag(0)
                            Text("two").tag(1)
                        }.frame(width: 70).padding(.leading, -7)
                    }
                    Text("New photos will be chosen at this specified period.").modifier(HintText())
                }
            }
        }.padding()
    }
}

struct GeneralPrefsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPrefsView()
    }
}
