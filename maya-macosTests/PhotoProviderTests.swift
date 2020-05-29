//
//  PhotoProviderTests.swift
//  maya-macosTests
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2020 KK. All rights reserved.
//

import XCTest
@testable import Maya

class PhotoProviderTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBookmark() {
        let url = URL(fileURLWithPath: "/home/kon/")
        let data = try? url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
        print("Bookmark data: ", data as Any)
    }

    func testICloud() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
