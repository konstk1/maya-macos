//
//  IAPManager.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/25/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation
import Combine
import StoreKit

enum IAPError: Error {
    case purchaseCancelled
    case genericPurchaseError
    case productRequestError

    var localizedDescription: String {
        switch self {
        case .purchaseCancelled: return "Purchase cancelled by user"
        case .genericPurchaseError: return "Generic purchase error"
        case .productRequestError: return "Product request error"
        }
    }
}

final class IAPManager: NSObject {
    var productsRequest: SKProductsRequest?

    var products: [SKProduct] = []
    let productPublisher = PassthroughSubject<[SKProduct], Never>()
    let purchasePublisher = PassthroughSubject<String, Never>()
    let errorPublisher = PassthroughSubject<Error, Never>()

    private let productIdentifiers: Set<String>

    init(productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
        super.init()
    }

    func startObservingPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }

    func stopObservingPaymentQueue() {
        SKPaymentQueue.default().remove(self)
    }

    func fetchProducts() {
        productsRequest?.cancel()
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }

    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    func buyProduct(_ productId: String) {
        guard let product = products.first(where: { $0.productIdentifier == productId }) else {
            log.error("Attempting to buy unavailalbe product: \(productId)")
            return
        }

        log.info("Purchasing \(product.productIdentifier): $\(product.price.floatValue)")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func restorePurchasedProducts() {
        log.info("Restoring completed transactions")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    private func cancelProductFetch() {
        productsRequest = nil
    }

    func price(for productId: String) -> String? {
        guard let product = products.first(where: { $0.productIdentifier == productId }) else {
            log.error("Price for unknown product: \(productId)")
            return nil
        }
        let priceFormatter = NumberFormatter()
        priceFormatter.formatterBehavior = .behavior10_4
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        return priceFormatter.string(from: product.price)
    }
}

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products

        for prod in products {
            log.verbose("Found \(prod.productIdentifier) \(prod.localizedTitle) $\(prod.price.floatValue)")
        }

        productPublisher.send(products)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        log.error("Failed to load list of products: \(error.localizedDescription)")

        // TODO: What to do on error?
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .restored:
                restore(transaction: transaction)
            case .deferred:
                log.debug("Transactiond deferred")      // nothing to do
            case .purchasing:
                log.debug("Transactiond purchasing")    // nothing to do
            @unknown default:
                log.warning("Unknown default")
            }
        }
    }

    private func complete(transaction: SKPaymentTransaction) {
        log.info("Completed transaction  for \(transaction.payment.productIdentifier)")
        SKPaymentQueue.default().finishTransaction(transaction)
        publishPurchase(identifier: transaction.payment.productIdentifier)
    }

    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        log.info("Restored \(productIdentifier)")
        SKPaymentQueue.default().finishTransaction(transaction)
        publishPurchase(identifier: transaction.original?.payment.productIdentifier)
    }

    private func fail(transaction: SKPaymentTransaction) {
        log.warning("Failed transcation")
        if let transactionError = transaction.error as NSError?,
            let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {
                log.error("Transaction error: \(localizedDescription)")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
        publishError(error: IAPError.genericPurchaseError)
    }

    private func publishPurchase(identifier: String?) {
        guard let identifier = identifier else {
            log.error("Nil identifier")
            return
        }

        purchasePublisher.send(identifier)
    }

    private func publishError(error: Error) {
        errorPublisher.send(error)
    }
}
