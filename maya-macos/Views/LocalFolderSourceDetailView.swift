//
//  LocalFolderSourceDetailView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct LocalFolderSourceDetailView: View {
    @ObservedObject private var model = LocalFolderViewModel()
    
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
        }.padding()
    }
}

struct LocalFolderSourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
//        LocalFolderSourceDetailView()
        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
