//
//  StoreManagerswift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/29/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation
import Combine

final class StoreManager: ObservableObject {
    static var shared = StoreManager()

    enum ProductId: String, CaseIterable {
        case applePhotosFreeTrial = "com.kk.maya_macos.apple_photos_free_trial"
        case applePhotosSource = "com.kk.maya_macos.apple_photos_full"
    }

    enum UnlockStatus: Equatable {
        case locked
        case freeTrial(daysRemaining: Int)
        case freeTrialExpired
        case purchased
    }

    enum IAPEvent {
        case productsUpdated
        case purchaseCompleted
        case failure(error: Error)
    }

    private let productIdentifiers: Set<String> = Set(ProductId.allCases.map { $0.rawValue })
//    var purchasedProductIdentifiers: Set<ProductId> = []

    private let iapMgr: IAPManager
    private var subs: Set<AnyCancellable> = []

    var eventPublisher = PassthroughSubject<IAPEvent, Never>()

    /// Most recent Apple Photos status. Note: it won't update if trial expired. Use `getApplePhotosStatus()` to get freshest status
    @Published var applePhotosSourceStatus: UnlockStatus

    private init() {
        iapMgr = IAPManager(productIdentifiers: productIdentifiers)

        applePhotosSourceStatus = StoreManager.getApplePhotosStatus()

        iapMgr.productPublisher.sink { [weak self] _ in
            self?.eventPublisher.send(.productsUpdated)
        }.store(in: &subs)

        // register for purchase notifications via publisher
        iapMgr.purchasePublisher.sink { [weak self] prodIdString in
            guard let self = self else { return }
            guard let prodId = ProductId(rawValue: prodIdString) else {
                log.warning("Unexpected product identifier: \(prodIdString)")
                return
            }
            StoreManager.persistPurchase(identifier: prodId)
            self.applePhotosSourceStatus = StoreManager.getApplePhotosStatus()
            self.eventPublisher.send(.purchaseCompleted)
        }.store(in: &subs)

        iapMgr.errorPublisher.sink { [weak self] error in
            self?.eventPublisher.send(IAPEvent.failure(error: error))
        }.store(in: &subs)

        iapMgr.fetchProducts()
    }

    func refreshProducts() {
        log.verbose("Refreshing products")
        iapMgr.fetchProducts()
    }

    func restorePurchases() {
        iapMgr.restorePurchasedProducts()
    }

    func startObservingPaymentQueue() {
        iapMgr.startObservingPaymentQueue()
    }

    func stopObservingPaymentQueue() {
        iapMgr.stopObservingPaymentQueue()
    }

    private static func persistPurchase(identifier: ProductId) {
        let dateFormatter = ISO8601DateFormatter()
        let dateStr = dateFormatter.string(from: Date())

        let data = iapEncrypt(text: dateStr)

        switch identifier {
        case .applePhotosFreeTrial:
            Settings.applePhotos.trialPurchasedData = data
        case .applePhotosSource:
            Settings.applePhotos.fullPurchasedData = data
        }
    }

    private static func checkPurchase(identifier: ProductId) -> Date? {
        // TODO: get value from UserDefaults
        var data: [UInt8]?

        switch identifier {
        case .applePhotosFreeTrial:
            data = Settings.applePhotos.trialPurchasedData
        case .applePhotosSource:
            data = Settings.applePhotos.fullPurchasedData
        }

        guard let purchaseData = data else {
            log.warning("No purchase data found for \(identifier)")
            return nil
        }

        guard let text = iapDecrypt(encrypted: purchaseData) else {
            log.error("Failed to decode purchase for \(identifier)")
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: text)

        return date
    }

    func refreshAllSourcesStatus() {
        applePhotosSourceStatus = StoreManager.getApplePhotosStatus()
    }
}

// MARK: Apple Photos IAP
extension StoreManager {
    static func getApplePhotosStatus() -> UnlockStatus {
        let applePhotosTrialDuration: TimeInterval = 14 * 24 * 3600      // 14 days (in seconds)

        var unlockStatus: UnlockStatus = .locked

        if checkPurchase(identifier: .applePhotosSource) != nil {
            // if valid date present for purchase product id, then it's been purchased
            unlockStatus = .purchased
        } else if let trialStartDate = checkPurchase(identifier: .applePhotosFreeTrial) {
            let endDate = trialStartDate.addingTimeInterval(applePhotosTrialDuration)
            let daysLeft = endDate.timeIntervalSince(Date()) / (24 * 3600)
            if daysLeft >= 0 {
                unlockStatus = .freeTrial(daysRemaining: Int(round(daysLeft)))
            } else {
                unlockStatus = .freeTrialExpired
            }
        } else {
            unlockStatus = .locked
        }

        return unlockStatus
    }

    func getApplePhotosPrice() -> String? {
        return iapMgr.price(for: ProductId.applePhotosSource.rawValue)
    }

    func buyApplePhotosTrial() {
        log.info("Purchasing apple photos trial: \(ProductId.applePhotosFreeTrial)")
        iapMgr.buyProduct(ProductId.applePhotosFreeTrial.rawValue)
    }

    func buyApplePhotosFull() {
        log.info("Purchasing apple photos full: \(ProductId.applePhotosSource)")
        iapMgr.buyProduct(ProductId.applePhotosSource.rawValue)
    }
}
