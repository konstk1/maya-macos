//
//  SourcesView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI
import SwiftyBeaver

struct ProviderRow: View {
    @EnvironmentObject var photoVendor: PhotoVendor

    var providerIndex: Int
    var isActive: Bool {
        return providerIndex == photoVendor.photoProviders.firstIndex { $0 === photoVendor.activeProvider }
    }
    
    var providerInfo: (name: String, image: NSImage) {
        switch photoVendor.photoProviders[providerIndex] {
        case is LocalFolderPhotoProvider:
            return (name: "Local Folder", image: NSImage(named: NSImage.folderName)!)
        case is GooglePhotoProvider:
            return (name: "Google Photos", image: NSImage(named: "GooglePhotos")!)
        default:
            log.warning("No view implemented for this provider")
            return (name: "Unknown", image: NSImage(named: NSImage.everyoneName)!)
        }
    }
    
    var body: some View {
        // use GeometryReader to make sure row takes up entire allocated space (for hit test)
        GeometryReader { g in
            HStack {
                ZStack {
                    Rectangle().frame(width: 20, height: 20).foregroundColor(.clear).border(Color.black, width: 1)
                    if self.isActive {
                        Image(nsImage: NSImage(named: NSImage.menuOnStateTemplateName)!)
                    }
                }.padding(.leading, 5)
                Image(nsImage: self.providerInfo.image).resizable().frame(width: 30, height: 30)
                Text(self.providerInfo.name)
                
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .leading)
        }
    }
}

struct SourcesView: View {
    @EnvironmentObject var photoVendor: PhotoVendor

    @State private var selectedProviderIdx: Int = 0
    
    func makeRow(at index: Int) -> some View {
        ZStack(alignment: .leading) {
            ProviderRow(providerIndex: index).frame(height: 40)
                .contentShape(Rectangle())
                .onTapGesture { self.selectedProviderIdx = index }
            
            if index == self.selectedProviderIdx {
                Rectangle().foregroundColor(Color.secondary.opacity(0.1)).frame(height: 40)
            }
        }
    }
    
    func detailView(for idx: Int) -> AnyView {
        if self.selectedProviderIdx == 0 {
            return AnyView(LocalFolderSourceDetailView())
        } else {
            return AnyView(ApiSourceDetailView())
        }
    }
    
    var body: some View {
        GeometryReader { g in
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<self.photoVendor.photoProviders.count) { i in
                        self.makeRow(at: i)
                    }
                    Spacer()
                }.frame(width: 200, height: g.size.height, alignment: .leading).background(Color.white)
                Divider()
                self.detailView(for: self.selectedProviderIdx)
            }
        }
    }
}

struct SourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
