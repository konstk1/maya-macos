//
//  GeneralPrefsView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/12/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct GeneralPrefsView: View {
    @ObservedObject private var prefs = GeneralPrefsViewModel()

    let titleWidth: CGFloat = 50
    let dividerWidth: CGFloat = 400
    let dividerPaddingVertical: CGFloat = 10
    let dividerPaddingHorizontal: CGFloat = -20

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 20) {
                Text("Startup:").frame(width: titleWidth, alignment: .trailing)

                VStack(alignment: .leading) {
                    Toggle(isOn: $prefs.appSettings.openAtLogin) {
                        Text("Open Maya at login")
                    }

                    Text("Start Maya automatically at login.").modifier(HintText())
                }
            }

            Divider()
                .frame(width: dividerWidth)
                .padding(.horizontal, dividerPaddingHorizontal)
                .padding(.vertical, dividerPaddingVertical)

            HStack(alignment: .top, spacing: 20) {
                Text("Frame:").frame(width: titleWidth, alignment: .trailing)

                VStack(alignment: .leading) {

                    Picker(selection: $prefs.newPhotoActionsSelection, label: Text("When new photos is ready").fixedSize()) {
                        ForEach(0..<prefs.newPhotoActions.count, id: \.self) { i in
                            Text(self.prefs.newPhotoActions[i]).tag(i).fixedSize()
                        }
                        }.frame(width: 310)

                    Text("Action to take when new photo is ready.").modifier(HintText())

                    HStack {

                        Toggle(isOn: $prefs.frameSettings.autoCloseFrame) {
                            Text("Automatically close after")
                        }

                        Picker("", selection: $prefs.autoCloseTimeSelection) {
                            ForEach(0..<GeneralPrefsViewModel.autoCloseTimeOptions.count, id: \.self) { i in
                                Text(GeneralPrefsViewModel.autoCloseTimeOptions[i].description).tag(i).fixedSize()
                            }
                        }.frame(width: 110).padding(.leading, -7)
                    }

                    Text("Photo frame will automatically close after this specified period.").modifier(HintText())
                }
            }

            Divider()
                .frame(width: dividerWidth)
                .padding(.horizontal, dividerPaddingHorizontal)
                .padding(.vertical, dividerPaddingVertical)

            HStack(alignment: .top, spacing: 20) {
                Text("Photos:").frame(width: titleWidth, alignment: .trailing)
                VStack(alignment: .leading) {
                    HStack {

                        Toggle(isOn: $prefs.photoSettings.autoSwitchPhoto) {
                            Text("Switch photos every").fixedSize()
                        }

                        Stepper(value: $prefs.photoSettings.autoSwitchPhotoPeriod.value, in: 1...1000) {
                            TextField("", value: $prefs.photoSettings.autoSwitchPhotoPeriod.value, formatter: NumberFormatter())
                                .multilineTextAlignment(.trailing)
                                .padding(.trailing, -5)
                        }.frame(width: 50)

                        Picker("", selection: $prefs.autoSwitchUnitSelection) {
                            ForEach(0..<GeneralPrefsViewModel.autoSwitchUnitsOptions.count, id: \.self) { i in
                                Text(GeneralPrefsViewModel.autoSwitchUnitsOptions[i]).fixedSize()
                            }
                        }.frame(width: 90).padding(.leading, -7)
                    }

                    Text("New photos will be chosen at this specified period.").modifier(HintText())
                }
            }
        }.padding(.horizontal, 40).padding(.vertical, 20)
            .frame(width: 460)
    }

    struct HintText: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

struct GeneralPrefsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPrefsView()
    }
}
