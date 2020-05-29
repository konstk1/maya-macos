//
//  AppleSourceDetailView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 3/17/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct AppleSourceDetailView: View {
    @ObservedObject private var model: AppleSourceViewModel

    init(apple: ApplePhotoProvider) {
        log.info("Init AppleSourceDetailView")
        model = AppleSourceViewModel(apple: apple)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Show photos from this album")
                Picker("", selection: $model.albumSelection) {
                    ForEach(0..<model.albumTitles.count, id: \.self) {
                        Text(self.model.albumTitles[$0]).truncationMode(.middle)
                    }
                }.labelsHidden()
            }.padding()

            Spacer()

            ActivateButton(isActive: model.isActive, action: model.activateClicked)

            //                Button(action: model.authorizeClicked) {
            //                    Text(model.isAuthorized ? "Authorize" : "Authorized")
            //                }.disabled(model.isAuthorized)
        }.padding(.bottom, 30)
    }
}

struct AppleSourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AppleSourceDetailView(apple: ApplePhotoProvider())
//        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
