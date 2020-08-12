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

    private var storeManager = StoreManager.shared

    init(apple: ApplePhotoProvider) {
        log.info("Init AppleSourceDetailView")
        model = AppleSourceViewModel(apple: apple)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Show photos from this album:")
                Picker("", selection: $model.albumSelection) {
                    ForEach(0..<model.albumTitles.count, id: \.self) {
                        Text(self.model.albumTitles[$0]).truncationMode(.middle)
                    }
                }.labelsHidden()
                Text("Tip: Change albums using dropdown above")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }.padding()

            Spacer()

            if !model.isAuthorized {
                VStack {
                    Text("Allow Maya access to Photos in Security & Privacy")
                    Button("Security & Privacy") {
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos")!
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            if model.trialDaysLeft >= 0 {
                Group {
                    Text("Enjoy your free trial, you have \(model.trialDaysLeft) days remaining.")
                    Text("No rush but if you'd like to unlock before trial expires:")
                    Button("Unlock $2.99") {
                        self.model.purchaseFull()
                    }
                }.font(.system(size: 12)).foregroundColor(.gray)
            }

            ZStack(alignment: .bottom) {
                Spacer()
                if model.isPurchasing {
                    Text("Purchasing...").foregroundColor(.primary)
                }
            }

            if model.isPurchased {
                ActivateButton(isActive: model.isActive, isPurchased: true, isTrialAvailable: false, action: model.activateClicked)
            } else {
                UnlockButtons(price: model.unlockPrice, isTrialAvailable: model.isTrialAvailable, onTrial: {
                    self.model.purchaseTrial()
                }, onUnlock: {
                    self.model.purchaseFull()
                })
            }
        }.padding(.bottom, 30).onAppear {
            self.model.refreshIaps()
        }.alert(isPresented: $model.isIapError) {
            Alert(title: Text("IAP Error"), message: Text("IAP error has occured. Ensure you have internet access and try again."), dismissButton: .default(Text("OK")))
        }
    }
}

struct AppleSourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AppleSourceDetailView(apple: ApplePhotoProvider())
//        SourcesView().environmentObject(PhotoVendor.shared)
    }
}
