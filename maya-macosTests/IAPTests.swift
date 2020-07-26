//
//  IAPTests.swift
//  maya-macosTests
//
//  Created by Konstantin Klitenik on 7/27/20.
//  Copyright © 2020 KK. All rights reserved.
//

import XCTest
@testable import Maya

class IAPTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEncrypt() throws {
        let date = Date()
        let formatter = ISO8601DateFormatter()
        let dateStr = formatter.string(from: date)

        let encrypted = iapEncrypt(text: dateStr)

        guard let decrypted = iapDecrypt(encrypted: encrypted) else {
            XCTFail("Failed decrypt")
            return
        }

        guard let decryptedDate = formatter.date(from: decrypted) else {
            XCTFail("Invalid date")
            return
        }

        XCTAssertLessThan(date.timeIntervalSince(decryptedDate), 1.0, "Decrypted date is too far off")

        var encryptedBad = encrypted
        encryptedBad[5] = 17    // inject bad data

        guard let decryptedBad = iapDecrypt(encrypted: encryptedBad) else {
            XCTFail("Failed decrypt")
            return
        }

        guard formatter.date(from: decryptedBad) == nil else {
            XCTFail("Invalid date was expected, valid date was found")
            return
        }
    }

}
