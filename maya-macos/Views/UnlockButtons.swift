//
//  UnlockButtons.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 5/29/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct UnlockButtons: View {
    var price: String
    var isTrialAvailable: Bool
    var onTrial: () -> Void
    var onUnlock: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onTrial) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Try Free")
                        Text("for 14 days").font(.system(size: 11))
                    }
                    Spacer()
                    Text("GET")
                }.padding(.horizontal, 17).contentShape(Rectangle())
            }.frame(width: 150, height: 50, alignment: .center)
                .background(RoundedRectangle(cornerRadius: 10)
                .fill(isTrialAvailable ? Color.mayaBlue : Color.tabBarSelected))
                .buttonStyle(PlainButtonStyle())
                .disabled(isTrialAvailable == false)
            Button(action: onUnlock) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Unlock")
                        Text("forever").font(.system(size: 11))
                    }
                    Spacer()
                    Text(price)
                }.padding(.horizontal, 20).contentShape(Rectangle())
            }.frame(width: 150, height: 50, alignment: .center)
                .background(RoundedRectangle(cornerRadius: 10)
                .fill(Color.mayaBlue))
                .buttonStyle(PlainButtonStyle())
        }
            .font(.subheadline)
            .foregroundColor(.white)
    }
}

struct UnlockButtons_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UnlockButtons(price: "$3.99", isTrialAvailable: false, onTrial: {}, onUnlock: {}).padding()
            UnlockButtons(price: "3.99$", isTrialAvailable: true, onTrial: {}, onUnlock: {}).padding()
        }
    }
}
