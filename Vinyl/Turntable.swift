//
//  Turntable.swift
//  Vinyl
//
//  Created by Rui Peres on 12/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

enum Error: ErrorType {
    
    case TrackNotFound
}

public typealias Plastic = [[String: AnyObject]]
typealias RequestCompletionHandler =  (NSData?, NSURLResponse?, NSError?) -> Void

public final class Turntable: NSURLSession {
    
    var errorHandler: ErrorHandler = DefaultErrorHandler()
    private let turntableConfiguration: TurntableConfiguration
    private var player: Player?
    private var recorder: Recorder?
    private var recordingSession: NSURLSession?
    private let operationQueue: NSOperationQueue
    
    public init(configuration: TurntableConfiguration, delegateQueue: NSOperationQueue? = nil, urlSession: NSURLSession? = nil) {
        
        turntableConfiguration = configuration
        if let delegateQueue = delegateQueue {
            operationQueue = delegateQueue
        } else {
            operationQueue = NSOperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
        }
        
        if configuration.recodingEnabled {
            recorder = Recorder(wax: Wax(tracks: []), recordingPath: configuration.recordingPath)
            recordingSession = urlSession ?? NSURLSession.sharedSession()
        }
        
        super.init()
    }
    
    public convenience init(vinyl: Vinyl, turntableConfiguration: TurntableConfiguration = TurntableConfiguration(), delegateQueue: NSOperationQueue? = nil, urlSession: NSURLSession? = nil) {
        self.init(configuration: turntableConfiguration, delegateQueue: delegateQueue, urlSession: urlSession)
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)
    }
    
    public convenience init(cassetteName: String, bundle: NSBundle = testingBundle(), turntableConfiguration: TurntableConfiguration = TurntableConfiguration(), delegateQueue: NSOperationQueue? = nil, urlSession: NSURLSession? = nil) {
        let vinyl = Vinyl(plastic: Turntable.createCassettePlastic(cassetteName, bundle: bundle))
        self.init(vinyl: vinyl, turntableConfiguration: turntableConfiguration, delegateQueue: delegateQueue, urlSession: urlSession)
    }
    
    public convenience init(vinylName: String, bundle: NSBundle = testingBundle(), turntableConfiguration: TurntableConfiguration = TurntableConfiguration(), delegateQueue: NSOperationQueue? = nil, urlSession: NSURLSession? = nil) {
        let plastic = Turntable.createVinylPlastic(vinylName, bundle: bundle, recordingMode: turntableConfiguration.recordingMode)
        let vinyl = Vinyl(plastic: plastic ?? [])
        self.init(vinyl: vinyl, turntableConfiguration: turntableConfiguration, delegateQueue: delegateQueue, urlSession: urlSession)
        
        switch turntableConfiguration.recordingMode {
        case .MissingVinyl where plastic == nil, .MissingTracks:
            recorder = Recorder(wax: Wax(vinyl: vinyl), recordingPath: recordingPath(fromConfiguration: turntableConfiguration, vinylName: vinylName, bundle: bundle))
        default:
            recorder = nil
            recordingSession = nil
        }
    }
    
    deinit {
        stopRecording()
    }
    
    public func stopRecording() {
        guard let _ = recordingSession else {
            return
        }
        
        recordingSession = nil
        persistRecording()
    }
    
    // MARK: - Private methods

    private func playVinyl<URLSessionTask: URLSessionTaskType>(request request: NSURLRequest, fromData bodyData: NSData? = nil, completionHandler: RequestCompletionHandler) throws -> URLSessionTask {
        guard let player = player else {
            fatalError("Did you forget to load the Vinyl? 🎶")
        }

        let completion = try player.playTrack(forRequest: transformRequest(request, bodyData: bodyData))

        return URLSessionTask {
            self.operationQueue.addOperationWithBlock {
                completionHandler(completion.data, completion.response, completion.error)
            }
        }
    }

    private func recordingHandler(request request: NSURLRequest, fromData bodyData: NSData? = nil, completionHandler: RequestCompletionHandler) -> RequestCompletionHandler {
        guard let recorder = recorder else {
            fatalError("No recording started.")
        }
        
        return {
            data, response, error in
            
            recorder.saveTrack(withRequest: self.transformRequest(request, bodyData: bodyData), urlResponse: response as? NSHTTPURLResponse, body: data, error: error)
            
            self.operationQueue.addOperationWithBlock {
                completionHandler(data, response, error)
            }
        }
    }
    
    private func transformRequest(request: NSURLRequest, bodyData: NSData? = nil) -> NSURLRequest {
        guard let bodyData = bodyData else {
            return request
        }

        guard let mutableRequest = request.mutableCopy() as? NSMutableURLRequest else {
            fatalError("💥 Houston, we have a problem 🚀")
        }

        mutableRequest.HTTPBody = bodyData

        return mutableRequest
    }

    private func recordingPath(fromConfiguration configuration: TurntableConfiguration, vinylName: String, bundle: NSBundle) -> String? {
        if let recordingPath = configuration.recordingPath {
            return recordingPath
        }
        
        return bundle.resourceURL?.URLByAppendingPathComponent(vinylName).URLByAppendingPathExtension("json").path
    }
    
    private func persistRecording() {
        guard let recorder = recorder else {
            return
        }
        
        do {
            try recorder.persist()
        }
        catch {
            fatalError("💣 we couldn't save the recording.")
        }
    }
    
    public override var delegate: NSURLSessionDelegate? {
        return nil
    }
}

// MARK: - NSURLSession methods

extension Turntable {
    
    public override func dataTaskWithURL(url: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
        let request = NSURLRequest(URL: url)
        return dataTaskWithRequest(request, completionHandler: completionHandler)
    }
    
    public override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
        
        do {
            return try playVinyl(request: request, completionHandler: completionHandler) as URLSessionDataTask
        }
        catch Error.TrackNotFound {
            if let session = recordingSession {
                return session.dataTaskWithRequest(request, completionHandler: recordingHandler(request: request, completionHandler: completionHandler))
            }
            else {
                errorHandler.handleTrackNotFound(request, playTracksUniquely: turntableConfiguration.playTracksUniquely)
            }
        }
        catch {
            errorHandler.handleUnknownError()
        }
        
        return URLSessionDataTask(completion: {})
    }
    
    public override func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask {
        
        do {
            return try playVinyl(request: request, fromData: bodyData, completionHandler: completionHandler) as URLSessionUploadTask
        }
        catch Error.TrackNotFound {
            if let session = recordingSession {
                return session.uploadTaskWithRequest(request, fromData: bodyData, completionHandler: recordingHandler(request: request, fromData: bodyData, completionHandler: completionHandler))
            }
            else {
                errorHandler.handleTrackNotFound(request, playTracksUniquely: turntableConfiguration.playTracksUniquely)
            }
        }
        catch {
            errorHandler.handleUnknownError()
        }
        
        return URLSessionUploadTask(completion: {})
    }
    
    public override func invalidateAndCancel() {
        // We won't do anything for
    }
}

// MARK: - Loading Methods

extension Turntable {
    
    public func loadVinyl(vinylName: String,  bundle: NSBundle = testingBundle()) {
        let plastic = Turntable.createVinylPlastic(vinylName, bundle: bundle, recordingMode: turntableConfiguration.recordingMode)
        let vinyl = Vinyl(plastic: plastic ?? [])
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)

        switch turntableConfiguration.recordingMode {
        case .MissingVinyl where plastic == nil, .MissingTracks:
            recorder = Recorder(wax: Wax(vinyl: vinyl), recordingPath: recordingPath(fromConfiguration: turntableConfiguration, vinylName: vinylName, bundle: bundle))
        default:
            recorder = nil
            recordingSession = nil
        }
    }
    
    public func loadCassette(cassetteName: String,  bundle: NSBundle = testingBundle()) {
        
        let vinyl = Vinyl(plastic: Turntable.createCassettePlastic(cassetteName, bundle: bundle))
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)
    }
    
    public func loadVinyl(vinyl: Vinyl) {
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)
    }
}

// MARK: - Bootstrap methods

extension Turntable {
    
    private static func createPlayer(vinyl: Vinyl, configuration: TurntableConfiguration) -> Player {
        
        let trackMatchers = configuration.trackMatchersForVinyl(vinyl)
        return Player(vinyl: vinyl, trackMatchers: trackMatchers)
    }
    
    private static func createCassettePlastic(cassetteName: String, bundle: NSBundle) -> Plastic {
        
        guard let cassette: [String: AnyObject] = loadJSON(bundle, fileName: cassetteName) else {
            fatalError("💣 Cassette file \"\(cassetteName)\" not found 😩")
        }
        
        guard let plastic = cassette["interactions"] as? Plastic else {
            fatalError("💣 We couldn't find the \"interactions\" key in your cassette 😩")
        }
        
        return plastic
    }
    
    private static func createVinylPlastic(vinylName: String, bundle: NSBundle, recordingMode: RecordingMode) -> Plastic? {
        if let plastic: Plastic = loadJSON(bundle, fileName: vinylName) {
            return plastic
        }

        switch recordingMode {
        case .None, .MissingTracks:
            fatalError("💣 Vinyl file \"\(vinylName)\" not found 😩")
        case .MissingVinyl:
            return nil
        }
    }
}
