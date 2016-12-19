//
//  URLSessionDataTask.swift
//  Vinyl
//
//  Created by Rui Peres on 16/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

public final class URLSessionDataTask: Foundation.URLSessionDataTask, URLSessionTaskType {
    
    fileprivate let completion: (Void) -> Void
    
    init(completion: @escaping (Void) -> Void) {
        self.completion = completion
    }
    
   public override func resume() {
        completion()
    }
    
   public override func suspend() {
        // We won't do anything here
    }
    
   public override func cancel() {
        // We won't do anything here
    }
}
