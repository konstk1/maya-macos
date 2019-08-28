//
//  GoogePhotoProviderTests.swift
//  maya-macosTests
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import XCTest
@testable import Maya

class GoogePhotoProviderTests: XCTestCase {
    let provider = GooglePhotoProvider.shared

    override func setUp() {
    }

    override func tearDown() {
    }

    func testAuth() {
        let expectation = XCTestExpectation(description: "Google OAuth")
        
        provider.authorize { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail("Failed auth")
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testAlbumList() {
        let expectation = XCTestExpectation(description: "Get album list")
        
        provider.listAlbums { result in
            defer { expectation.fulfill() }
            guard case let .success(albums) = result else { XCTFail("Non success result"); return }
            XCTAssert(albums.count > 0, "No albums present in response")
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAlbumContents() {
        let expectation = self.expectation(description: "Get album contents")
        
        let album = GooglePhotos.Album(id: "AHSlkqOFrKbKoVNTsYL7lrtF6Y8MHnwVMZeKKs0rnY9E30ZCNzTgWWlsGDQT58lCH2CM8r6FLmmu", title: "", productUrl: "", mediaItemsCount: "", coverPhotoBaseUrl: "", coverPhotoMediaItemId: "")
        
        provider.listPhotos(for: album) { (result) in
            defer { expectation.fulfill() }
            guard case let .success(photos) = result else { XCTFail("Non success result"); return }
            print(photos.first!.id)
            XCTAssert(photos.count > 0, "No albums present in response")
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetPhoto() {
        let expectation = self.expectation(description: "Get photo")
    
        let photoId = "AHSlkqOwJsY7KZT4P7sestzFTKnw1GWiHKlMoJePb7AFmz_poNdeXDjuZ2BogLFg6UKY3XBqcElwJHF-avti-_EeMW_WH0Zj7A"
        
        provider.getPhoto(id: photoId) { (result) in
            defer { expectation.fulfill() }
            guard case .success(let image) = result else { XCTFail("Failed to get image"); return }
            print("Image size \(image.size)")
            XCTAssert(image.size.height > 0, "Zero height")
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
