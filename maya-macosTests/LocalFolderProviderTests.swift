//
//  LocalFolderProviderTests.swift
//  maya-macosTests
//
//  Created by Konstantin Klitenik on 4/19/20.
//  Copyright © 2020 KK. All rights reserved.
//

import XCTest
import Combine
@testable import Maya

class LocalFolderProviderTests: XCTestCase {
    let provider = LocalFolderPhotoProvider()

    override func setUpWithError() throws {
        provider.clearPhotoAssets()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFolderList() throws {
        let expectation = self.expectation(description: "List folder")

        _ = provider.refreshAssets().sink(receiveCompletion: { _ in }, receiveValue: { assets in
            print("Listed \(assets.count)")
            XCTAssertGreaterThan(assets.count, 0, "Expected photos in folder")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPhotoPublisher() throws {
        let expectation = self.expectation(description: "List folder")

        var sinkCount = 0

        let sub = provider.$photoDescriptors.sink(receiveCompletion: { _ in }, receiveValue: { assets in
            sinkCount += 1

            print("Listed \(assets.count)")
            switch sinkCount {
            case 1:
                XCTAssertEqual(assets.count, 0, "Expected no photos on first call")
            default:
                XCTAssertGreaterThan(assets.count, 0, "Expected photos on subsquent calls")
            }

            if sinkCount == 2 {
                expectation.fulfill()
            }
        })

        XCTAssertNotNil(sub)

        provider.refreshAssets()

        waitForExpectations(timeout: 3.0, handler: nil)
    }

}
