//
//  GoogePhotoProviderTests.swift
//  maya-macosTests
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import XCTest
import Combine
@testable import Maya

class GoogePhotoProviderTests: XCTestCase {
    let google = GooglePhotoProvider()
    
    var subs: Set<AnyCancellable> = []

    override func setUp() {
    }

    override func tearDown() {
    }

    func testAuth() {
        let expectation = XCTestExpectation(description: "Google OAuth")

        google.authorize().sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed auth: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }) { _ in /* nothing to do here */ }.store(in: &subs)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAlbumList() {
        let expectation = XCTestExpectation(description: "Get album list")
        
        google.listAlbums().sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                XCTFail("Non success result: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }) { albums in
            XCTAssert(albums.count > 51, "No albums present in response")
            expectation.fulfill()
        }.store(in: &subs)

        wait(for: [expectation], timeout: 10.0)
    }

    func testAlbumListPublisher() {
        let expectation = XCTestExpectation(description: "Get album list")

        var callCount = 0

        google.albumsPublisher.sink { albums in
            callCount += 1
            print("Sinking publisher results \(callCount) - \(albums.count)")
            if callCount == 1 {
                XCTAssert(albums.count == 0, "Non zero albums on init")
            } else if callCount == 4 {
                XCTAssertGreaterThan(albums.count, 51, "Not all albums listed")
                expectation.fulfill()
            }
        }.store(in: &subs)

        google.listAlbums()

        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAlbumContents() {
        let expectation = self.expectation(description: "Get album contents")
        
        let album = GooglePhotos.Album(id: "AHSlkqOFrKbKoVNTsYL7lrtF6Y8MHnwVMZeKKs0rnY9E30ZCNzTgWWlsGDQT58lCH2CM8r6FLmmu", title: "", productUrl: "", mediaItemsCount: "", coverPhotoBaseUrl: "", coverPhotoMediaItemId: "")

        google.listPhotos(for: album).sink(receiveCompletion: { _ in }) { photos in
            print(photos.first!.description)
            XCTAssert(photos.count > 0, "No photos present in response")
            expectation.fulfill()
        }.store(in: &subs)

        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetPhoto() {
        let expectation = self.expectation(description: "Get photo")
    
        let photoId = "AHSlkqOwJsY7KZT4P7sestzFTKnw1GWiHKlMoJePb7AFmz_poNdeXDjuZ2BogLFg6UKY3XBqcElwJHF-avti-_EeMW_WH0Zj7A"

        google.getPhoto(id: photoId).sink(receiveCompletion: { _ in }) { image in
            print("Image size \(image.size)")
            XCTAssert(image.size.height > 0, "Zero height")
            expectation.fulfill()
        }.store(in: &subs)
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testGetPhotoError() {
        let exp1 = self.expectation(description: "Future promise")
        let exp2 = self.expectation(description: "Published promise")

        let photoId = "AHS"

        let sub = google.$error.sink { error in
            if error != .none {
                print("Published error: \(error)")
                exp2.fulfill()
            }
        }

        google.getPhoto(id: photoId).sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                print("Future error: \(error)")
                break   // expected case, nothing to do
            case .finished:
                XCTFail("Unexpected finished")
            }
            exp1.fulfill()
        }) { image in
            XCTFail("Unexpected image procuded")
            exp1.fulfill()
        }.store(in: &subs)

        waitForExpectations(timeout: 3.0, handler: nil)
    }

}
