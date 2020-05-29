//
//  LocalFolderSourceDetailView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct LocalFolderSourceDetailView: View {
    @ObservedObject private var model: LocalFolderViewModel

    init(provider: LocalFolderPhotoProvider) {
        log.warning("Init LocalFolderSourceDetailView")
        model = LocalFolderViewModel(provider: provider)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Show photos from this location")
            Picker("", selection: $model.folderSelection) {
                ForEach(0..<model.recentFolders.count, id: \.self) {
                    Text(self.model.recentFolders[$0]).truncationMode(.middle)
                }
                Divider()
                Text("Choose a new folder...").onTapGesture {
                    print("New folder")
                }.tag(5)
            }.labelsHidden()

            Spacer()

            Button(action: model.activateClicked) {
                Text(model.isActive ? "Active" : "Activate")
            }.disabled(model.isActive)
        }.padding()
    }
}

struct LocalFolderSourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
//        LocalFolderSourceDetailView()
        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
