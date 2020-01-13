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
    
    var body: some View {
        VStack {
            HStack {
                Text("Startup:").frame(alignment: .trailing)
                VStack(alignment: .leading) {
                    Toggle(isOn: $openAtLogin) {
                        Text("Open Maya at login")
                    }
                    Text("Start Maya automatically at login.").font(.system(size: 10))
                }
            }
            Divider().frame(width: 400)
            HStack {
                Text("Frame:")
            }
            Divider().frame(width: 400)
            HStack {
                Text("Photos")
            }
        }.padding()
    }
}

struct GeneralPrefsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPrefsView()
    }
}
