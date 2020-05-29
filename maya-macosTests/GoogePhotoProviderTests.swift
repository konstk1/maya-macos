//
//  GoogePhotoProviderTests.swift
//  maya-macosTests
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2020 KK. All rights reserved.
//

import XCTest
import Combine
@testable import Maya

// swiftlint:disable force_unwrapping

class GoogePhotoProviderTests: XCTestCase {
    let google = GooglePhotoProvider()

    override func setUp() {
    }

    override func tearDown() {
    }

    func testAuth() {
        let expectation = XCTestExpectation(description: "Google OAuth")

        let sub = google.authorize().sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed auth: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }, receiveValue: { _ in /* nothing to do here */ })

        wait(for: [expectation], timeout: 5.0)
        sub.cancel()
    }

    func testAlbumList() {
        let expectation = XCTestExpectation(description: "Get album list")

        let sub = google.listAlbums().sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                XCTFail("Non success result: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }, receiveValue: { albums in
            XCTAssert(albums.count > 51, "No albums present in response")
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10.0)
        sub.cancel()
    }

    func testAlbumListPublisher() {
        let expectation = XCTestExpectation(description: "Get album list")

        var callCount = 0

        let sub = google.albumsPublisher.sink { albums in
            callCount += 1
            print("Sinking publisher results \(callCount) - \(albums.count)")
            if callCount == 1 {
                XCTAssert(albums.isEmpty, "Non zero albums on init")
            } else if callCount == 4 {
                XCTAssertGreaterThan(albums.count, 51, "Not all albums listed")
                expectation.fulfill()
            }
        }

        google.listAlbums()

        wait(for: [expectation], timeout: 10.0)
        sub.cancel()
    }

    func testAlbumContents() {
        let expectation = self.expectation(description: "Get album contents")

        let album = GooglePhotos.Album(id: "AHSlkqOFrKbKoVNTsYL7lrtF6Y8MHnwVMZeKKs0rnY9E30ZCNzTgWWlsGDQT58lCH2CM8r6FLmmu", title: "", productUrl: "", mediaItemsCount: "", coverPhotoBaseUrl: "", coverPhotoMediaItemId: "")

        let sub = google.listPhotos(for: album).sink(receiveCompletion: { _ in }, receiveValue: { photos in
            print(photos.first!.description)
            XCTAssertGreaterThan(photos.count, 0, "No photos present in response")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10.0, handler: nil)
        sub.cancel()
    }

    func testGetPhoto() {
        let expectation = self.expectation(description: "Get photo")

        let photoId = "AHSlkqOwJsY7KZT4P7sestzFTKnw1GWiHKlMoJePb7AFmz_poNdeXDjuZ2BogLFg6UKY3XBqcElwJHF-avti-_EeMW_WH0Zj7A"

        let sub = google.getPhoto(id: photoId).sink(receiveCompletion: { _ in }, receiveValue: { image in
            print("Image size \(image.size)")
            XCTAssert(image.size.height > 0, "Zero height")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 3.0, handler: nil)
        sub.cancel()
    }

    func testGetPhotoError() {
        let exp1 = self.expectation(description: "Future promise")
        let exp2 = self.expectation(description: "Published promise")

        let photoId = "AHS"

        let errorSub = google.$error.sink { error in
            if error != .none {
                print("Published error: \(error)")
                exp2.fulfill()
            }
        }

        let photoSub = google.getPhoto(id: photoId).sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                print("Future error: \(error)")
            case .finished:
                XCTFail("Unexpected finished")
            }
            exp1.fulfill()
        }, receiveValue: { _ in
            XCTFail("Unexpected image procuded")
            exp1.fulfill()
        })

        waitForExpectations(timeout: 3.0, handler: nil)
        errorSub.cancel()
        photoSub.cancel()
    }

}
