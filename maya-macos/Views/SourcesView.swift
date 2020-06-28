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

struct SourcesView: View {
    @EnvironmentObject var photoVendor: PhotoVendor

    @State private var selectedProviderIdx: Int = 0

    init() {
        log.info("Sources view init")
    }

    func makeRow(at index: Int) -> some View {
        ZStack(alignment: .leading) {
            ProviderRow(providerIndex: index).frame(height: 40)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.selectedProviderIdx = index
                    }
                }

            if index == self.selectedProviderIdx {
                // disallow hit testing to send taps to provider row below
                Rectangle().foregroundColor(Color.secondary.opacity(0.1)).frame(height: 40).allowsHitTesting(false)
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<self.photoVendor.photoProviders.count) { i in
                    self.makeRow(at: i)
                }
                Spacer()
            }
            .frame(width: 220)
            .background(Color.aboutBackground)

            Divider()

            DetailView(provider: self.photoVendor.photoProviders[self.selectedProviderIdx])
                .frame(width: 360)
                .transition(.opacity)
//                .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
        }.onAppear {
            print("On Appear")
            self.selectedProviderIdx = self.photoVendor.activeProviderIndex ?? 0
        }.frame(height: 250)
    }
}

struct DetailView: View {
    private var provider: PhotoProvider

    init(provider: PhotoProvider) {
        self.provider = provider
    }

    var body: some View {
        Group {
            // swiftlint:disable force_cast
            if provider.type == .localFolder {
                LocalFolderSourceDetailView(provider: provider as! LocalFolderPhotoProvider)
            } else if provider.type == .googlePhotos {
                GoogleSourceDetailView(google: provider as! GooglePhotoProvider)
            } else if provider.type == .applePhotos {
                AppleSourceDetailView(apple: provider as! ApplePhotoProvider)
            }
            // swiftlint:enable force_cast
        }
    }
}
struct ProviderRow: View {
    @EnvironmentObject var photoVendor: PhotoVendor

    var providerIndex: Int

    // this needs to be a computed property as lazy vars are mutating and photoVendor is not yet available during init()
    // TODO: can this be made into a "computed-once property"?
    var photoCountPublisher: AnyPublisher<Int, Never> {
        //        print("Making count publisher for index \(providerIndex)")
        let currentCount = photoVendor.photoProviders[providerIndex].photoDescriptors.count
        let currentSubject = CurrentValueSubject<Int, Never>(currentCount)
        let countPublisher = NotificationCenter.default.publisher(for: .updatePhotoCount, object: photoVendor.photoProviders[providerIndex])
            .map { $0.userInfo?["photoCount"] as? Int ?? 0 }
        return currentSubject.merge(with: countPublisher).receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    private var isActive: Bool {
        return providerIndex == photoVendor.activeProviderIndex
    }

    @State private var photoCount = 0

    var providerInfo: (name: String, image: NSImage) {
        switch photoVendor.photoProviders[providerIndex].type {
        case .localFolder:
            return (name: "Local Folder", image: NSImage(named: NSImage.folderName)!)  // swiftlint:disable:this force_unwrapping
        case .googlePhotos:
            return (name: "Google Photos", image: #imageLiteral(resourceName: "GooglePhotos"))
        case .applePhotos:
            return (name: "Apple Photos", image: #imageLiteral(resourceName: "ApplePhotos"))
        default:
            log.warning("No view implemented for this provider")
            return (name: "Unknown", image: NSImage(named: NSImage.everyoneName)!)    // swiftlint:disable:this force_unwrapping
        }
    }

    var body: some View {
        HStack {
            ZStack {
                Rectangle().frame(width: 20, height: 20).foregroundColor(.clear).border(Color.clear, width: 0)

                if self.isActive {
                    Image(nsImage: NSImage.checkbox).resizable().scaledToFit().frame(width: 15).foregroundColor(.checkmark)
                }
            }.padding(.leading, 5).padding(.trailing, 0)

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
    }
}

struct SourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
