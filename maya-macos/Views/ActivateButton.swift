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

    var body: some View {
        Button(action: action) {
            HStack {
                Image(nsImage: isActive ? NSImage.checkbox : NSImage.play)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text(isActive ? "Active" : "Activate")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .frame(width: 140, height: 40, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 10).fill(isActive ? Color.mayaGreen : Color.mayaBlue))
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
