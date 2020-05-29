//
//  PhotoFrameView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/18/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct PhotoFrameView: View {
    // TODO: replace this with another placeholder image
    private var image = NSImage(named: NSImage.everyoneName)!       // swiftlint:disable:this force_unwrapping

    @State private var scale: CGFloat = 1.0
    @State private var zoomLocation: UnitPoint = .center

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            Image(nsImage: image).resizable().scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
        }.frame(width: 200, height: 200).onTapGesture(count: 2) {
            print("DoubleTap")
            self.scale = 4.0 - self.scale
        }
    }
}

struct PhotoFrameView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoFrameView()
    }
}
