//
//  ActivateButton.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 5/29/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct ActivateButton: View {
    var isActive: Bool
    var action: () -> Void

    private var buttonConfig: (text: String, icon: NSImage, color: Color) {
        if isActive {
            return ("Active", NSImage.checkbox, Color.mayaGreen)
        } else {
            return ("Activate", NSImage.play, Color.mayaBlue)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(nsImage: buttonConfig.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text(buttonConfig.text)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .frame(width: 140, height: 40, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 10).fill(buttonConfig.color))
        }.buttonStyle(PlainButtonStyle())
    }
}

struct ActivateButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivateButton(isActive: false) {}.padding()
            ActivateButton(isActive: true) {}.padding()
        }
    }
}
