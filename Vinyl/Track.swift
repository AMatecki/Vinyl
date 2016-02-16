//
//  Track.swift
//  Vinyl
//
//  Created by David Rodrigues on 14/02/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

typealias EncodedObject = [String : AnyObject]
typealias HTTPHeaders = [String : String]

typealias Request = NSURLRequest

struct Response {
    let urlResponse: NSURLResponse
    let body: NSData?
    let error: NSError?
}

struct Track {
    let request: Request
    let response: Response
}

extension Track {
    
    init(encodedTrack: EncodedObject) {
        guard
            let encodedRequest = encodedTrack["request"] as? EncodedObject,
            let encodedResponse = encodedTrack["response"] as? EncodedObject
        else {
            fatalError("request/response not found 😞 for Track: \(encodedTrack)")
        }
        
        // We're using a helper function because we cannot mutate a NSURLRequest directly
        request = Request.createWithEncodedRequest(encodedRequest)
        
        response = Response(encodedResponse: encodedResponse)
    }
}

extension NSURLRequest {
    
    class func createWithEncodedRequest(encodedRequest: EncodedObject) -> NSURLRequest {
        guard
            let urlString = encodedRequest["url"] as? String,
            let url = NSURL(string: urlString)
        else {
            fatalError("URL not found 😞 for Request: \(encodedRequest)")
        }
        
        let request = NSMutableURLRequest(URL: url)
        
        if let method = encodedRequest["method"] as? String {
            request.HTTPMethod = method
        }
        
        if let headers = encodedRequest["headers"] as? HTTPHeaders {
            request.allHTTPHeaderFields = headers
        }
        
        if let body = encodedRequest["body"] as? NSData {
            request.HTTPBody = body
        }
        
        return request
    }
}

extension Response {
    
    init(encodedResponse: EncodedObject) {
        guard
            let urlString = encodedResponse["url"] as? String,
            let url =  NSURL(string: urlString),
            let statusCode = encodedResponse["statusCode"] as? Int,
            let headers = encodedResponse["headers"] as? HTTPHeaders,
            let urlResponse = NSHTTPURLResponse(URL: url, statusCode: statusCode, HTTPVersion: nil, headerFields: headers)
        else {
            fatalError("key not found 😞 for Response (check url/statusCode/headers) \(encodedResponse)")
        }
        
        self.init(urlResponse: urlResponse, body: decodeBody(encodedResponse["body"], headers: headers), error: nil)
    }
}
