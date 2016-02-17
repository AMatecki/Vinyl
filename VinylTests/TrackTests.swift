//
//  TrackTests.swift
//  Vinyl
//
//  Created by Rui Peres on 17/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import XCTest
@testable import Vinyl

class TrackTests: XCTestCase {

    func test_badTrackCreation() {
        
        let track = TrackFactory.createBadTrack(NSURL(string: "http://badRecord.com")!, statusCode: 400)
        
        XCTAssertTrue(track.response.urlResponse.statusCode == 400)
        XCTAssertTrue(track.response.urlResponse.URL?.absoluteString == "http://badRecord.com")
        XCTAssertTrue(track.request.URL?.absoluteString == "http://badRecord.com")
    }
    
    func test_badTrackCreation_withError() {
        
        let error = NSError(domain: "Test Domain", code: 1, userInfo: nil)
        let track = TrackFactory.createBadTrack(NSURL(string: "http://badRecord.com")!, statusCode: 400, error: error)
        
        XCTAssertTrue(track.response.urlResponse.statusCode == 400)
        XCTAssertTrue(track.response.error == error)
        XCTAssertTrue(track.response.urlResponse.URL?.absoluteString == "http://badRecord.com")
        XCTAssertTrue(track.request.URL?.absoluteString == "http://badRecord.com")
    }

    func test_AwesomeTrackCreation() {
        
        let data = "Hello World".dataUsingEncoding(NSUTF8StringEncoding)!
        let headers = ["awesomeness": "max"]
        
        let track = TrackFactory.createValidTrack(NSURL(string: "http://feelGoodINC.com")!, body: data, headers: headers)
        
        XCTAssertTrue(track.response.urlResponse.statusCode == 200)
        XCTAssertTrue(track.response.body!.isEqualToData(data))
        XCTAssertTrue(track.response.urlResponse.allHeaderFields as! HTTPHeaders == headers)
        XCTAssertTrue(track.response.urlResponse.URL?.absoluteString == "http://feelGoodINC.com")
        XCTAssertTrue(track.request.URL?.absoluteString == "http://feelGoodINC.com")
    }
}
