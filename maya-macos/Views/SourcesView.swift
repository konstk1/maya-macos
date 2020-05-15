//
//  SourcesView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI
import Combine
import SwiftyBeaver

struct ProviderRow: View {
    @EnvironmentObject var photoVendor: PhotoVendor

    var providerIndex: Int
    
    // this needs to be a computed property as lazy vars are mutating and photoVendor is not yet available during init()
    // TODO: can this be made into a "computed-once property"?
    var photoCountPublisher: AnyPublisher<Int, Never> {
        print("Making count publisher for index \(providerIndex)")
        let currentCount = photoVendor.photoProviders[providerIndex].photoDescriptors.count
        let currentSubject = CurrentValueSubject<Int, Never>(currentCount)
        let countPublisher = NotificationCenter.default.publisher(for: .updatePhotoCount, object: photoVendor.photoProviders[providerIndex])
            .map { $0.userInfo?["photoCount"] as? Int ?? 0 }
        return currentSubject.merge(with: countPublisher).receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    private var isActive: Bool {
        return providerIndex == photoVendor.photoProviders.firstIndex { $0 === photoVendor.activeProvider }
    }
    
    @State private var photoCount = 0
        
    var providerInfo: (name: String, image: NSImage) {
        switch photoVendor.photoProviders[providerIndex].type {
        case .localFolder:
            return (name: "Local Folder", image: NSImage(named: NSImage.folderName)!)
        case .googlePhotos:
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
                    .contentShape(Rectangle()).onTapGesture {
                        print("Activating \(self.providerIndex)")
                        self.photoVendor.setActiveProvider(self.photoVendor.photoProviders[self.providerIndex])
                    }
                    if self.isActive {
                        Image(nsImage: NSImage(named: NSImage.menuOnStateTemplateName)!)
                    }
                }.padding(.leading, 5)
                Image(nsImage: self.providerInfo.image).resizable().frame(width: 30, height: 30)
                Text(self.providerInfo.name).lineLimit(1)
                Spacer()
                Text("\(self.photoCount)")
                    .padding(.horizontal, 5).frame(minWidth: 35, minHeight: 20)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .background(Color.gray)
                    .clipShape(Capsule())
                    .padding(.trailing, 10)
                    .onReceive(self.photoCountPublisher) { photoCount in
                        self.photoCount = photoCount
                    }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .leading)
        }
    }
}

struct SourcesView: View {
    @EnvironmentObject var photoVendor: PhotoVendor

    @State private var selectedProviderIdx: Int = 0

    init() {
        log.info("Sources view init")
    }
    
    func makeRow(at index: Int) -> some View {
        ZStack(alignment: .leading) {
            ProviderRow(providerIndex: index).environmentObject(self.photoVendor).frame(height: 40)
                .contentShape(Rectangle())
                .onTapGesture { self.selectedProviderIdx = index }
            
            if index == self.selectedProviderIdx {
                // disallow hit testing to send taps to provider row below
                Rectangle().foregroundColor(Color.secondary.opacity(0.1)).frame(height: 40).allowsHitTesting(false)
            }
        }
    }
    
    func detailView(for idx: Int) -> AnyView {
        // TODO: rework this!
        if self.selectedProviderIdx == 0 {
            return AnyView(LocalFolderSourceDetailView(provider: photoVendor.photoProviders[selectedProviderIdx] as! LocalFolderPhotoProvider))
        } else if self.selectedProviderIdx == 1 {
            return AnyView(GoogleSourceDetailView(google: photoVendor.photoProviders[selectedProviderIdx] as! GooglePhotoProvider))
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
                }.frame(width: 220, height: g.size.height, alignment: .leading).background(Color.white)
                Divider()
                self.detailView(for: self.selectedProviderIdx).frame(width: g.size.width - 220, height: g.size.height, alignment: .top).offset(x: 0, y: 10)
            }
        }
    }
}

struct SourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
