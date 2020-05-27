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
                XCTAssert(albums.count == 0, "Non zero albums on init")
            } else if callCount == 2 {
                XCTAssertEqual(albums.count, 3, "Not all albums listed")
                expectation.fulfill()
            }
        }

        apple.listAlbums()

        wait(for: [expectation], timeout: 10.0)
    }

    func testAlbumContents() {
        let album = apple.listAlbums().first!
        let photos = apple.listPhotos(for: album)

        print(photos.first!)
        XCTAssert(photos.count > 0, "No photos present in response")
    }

    func testGetPhoto() {
        let expectation = self.expectation(description: "Get photo")

        let album = apple.listAlbums().first!
        let photo = apple.listPhotos(for: album).first!

        let sub = photo.fetchImage(using: apple).sink(receiveCompletion: { _ in }) { image in
            print("Image size \(image.size)")
            XCTAssertGreaterThan(image.size.height, 100, "Incorrect height")
            XCTAssertGreaterThan(image.size.width, 100, "Incorrect width")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0, handler: nil)
    }
}
