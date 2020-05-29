//
//  ApplePhotoProviderTests.swift
//  maya-macosTests
//
//  Created by Konstantin Klitenik on 5/26/20.
//  Copyright © 2020 KK. All rights reserved.
//

import XCTest
import Combine
import Photos
@testable import Maya

// swiftlint:disable force_unwrapping

class ApplePhotoProviderTests: XCTestCase {
    let apple = ApplePhotoProvider()

    override func setUpWithError() throws {
        apple.authorize()
    }

    override func tearDownWithError() throws {
    }

    func testAlbumListPublisher() {
        let expectation = XCTestExpectation(description: "Get album list")

        var callCount = 0

        let sub = apple.albumsPublisher.sink { albums in
            callCount += 1
            print("Sinking publisher results \(callCount) - \(albums.count)")
            if callCount == 1 {
                XCTAssert(albums.isEmpty, "Non zero albums on init")
            } else if callCount == 2 {
                XCTAssertEqual(albums.count, 5, "Not all albums listed")
                expectation.fulfill()
            }
        }

        apple.listAlbums()

        wait(for: [expectation], timeout: 10.0)
        sub.cancel()
    }

    func testAlbumContents() {
        let album = apple.listAlbums().first!
        let photos = apple.listPhotos(for: album)

        print(photos.first!)
        XCTAssertGreaterThan(photos.count, 0, "No photos present in response")
    }

    func testGetPhoto() {
        let expectation = self.expectation(description: "Get photo")

        let album = apple.listAlbums().first!
        let photo = apple.listPhotos(for: album).first!

        let asset = ApplePhotoAsset(asset: photo)

        let sub = asset.fetchImage(using: apple).sink(receiveCompletion: { _ in }, receiveValue: { image in
            print("Image size \(image.size)")
            XCTAssertGreaterThan(image.size.height, 100, "Incorrect height")
            XCTAssertGreaterThan(image.size.width, 100, "Incorrect width")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 3.0, handler: nil)
        sub.cancel()
    }
}
