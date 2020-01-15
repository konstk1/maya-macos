//
//  SourcesView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct SourceRow: View {
    var provider: PhotoProvider
    
    var providerInfo: (name: String, image: NSImage) {
        switch provider {
        case is LocalFolderPhotoProvider:
            return (name: "Local Folder", image: NSImage(named: NSImage.folderName)!)
        case is GooglePhotoProvider:
            return (name: "Google Photos", image: NSImage(named: "GooglePhotos")!)
        default:
            return (name: "Unknown", image: NSImage(named: NSImage.everyoneName)!)
        }
    }
    
    var body: some View {
        HStack {
            Image(nsImage: providerInfo.image).resizable().frame(width: 30, height: 30)
            Text(providerInfo.name)
        }
    }
}

struct SourcesView: View {
    let providers = PhotoVendor.shared.photoProviders
    
    @State private var selectedSourceTag: Int?
    
    var body: some View {
        NavigationView {
            List(selection: $selectedSourceTag) {
                NavigationLink(destination: LocalFolderSourceDetailView(), tag: 0, selection: $selectedSourceTag) {
                    SourceRow(provider: providers[0])
                }.tag(0)
                NavigationLink(destination: ApiSourceDetailView(), tag: 1, selection: $selectedSourceTag) {
                    SourceRow(provider: providers[1])
                }.tag(1)
            }.frame(width: 200, height: 200)
            LocalFolderSourceDetailView()
        }.frame(width: 400, height: 200)
    }
}

struct SourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SourcesView().frame(width: 400, height: 200)
    }
}
