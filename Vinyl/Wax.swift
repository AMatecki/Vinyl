//
//  Wax.swift
//  Vinyl
//
//  Created by Michael Brown on 07/08/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

struct Wax {
    
    var tracks: [Track] = []
    var baseTracks: [Track] = []
    
    init(vinyl: Vinyl,
         baseVinyl: Vinyl? = nil) {
        tracks.append(contentsOf: vinyl.tracks)
        if let baseVinyl = baseVinyl {
            baseTracks.append(contentsOf: baseVinyl.tracks)
        }
    }
    
    init(tracks: [Track]) {
        self.tracks.append(contentsOf: tracks)
    }
    
    mutating func add(track: Track) {
        if baseTracks.filter({
            (baseTrack) -> Bool in
            baseTrack.request.url == track.request.url
        }).isEmpty {
            tracks.append(track)
        }
    }
}
