//
//  GoogleSourceDetailView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 3/17/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct GoogleSourceDetailView: View {
    @ObservedObject private var model: GoogleSourceViewModel

    init(google: GooglePhotoProvider) {
        model = GoogleSourceViewModel(google: google)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Show photos from this album")
            Picker("", selection: $model.albumSelection) {
                ForEach(0..<model.albumTitles.count, id: \.self) {
                    Text(self.model.albumTitles[$0]).truncationMode(.middle)
                }
            }.labelsHidden()
        }.padding()
    }
}

struct GoogleSourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSourceDetailView(google: GooglePhotoProvider())
//        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
