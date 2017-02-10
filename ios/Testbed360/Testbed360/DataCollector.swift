//
//  DataCollector.swift
//  Testbed360
//
//  Created by Evgeniy Upenik on 20/06/16.
//
//  Copyright (C) 2017 ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland
//  Multimedia Signal Processing Group
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

class DataCollector: NSObject {
    
//    struct AttitudePos {
//        var timestamp: Double
//        var horiz: Double
//        var vert: Double
//        var roll: Double
//    }
    struct Vote {
        var file: String    // File name of the eveluated picture
        var grade: Int      // Grade in scale of 1 to 5
        var track: Double   // Timestamp of the first poit in direction track
    }
    
    private let timestampID: Int64
    private var votes: Array<Vote> = [] // TODO: Change to Array!!!
    //private var votes: NSArray = [] // TODO: Change to Array!!!
    private var track: Array<Double> = []
    private var tracks: Array<Array<Double>> = []
    private var trackN: Int = 0
    private var isTracking = false

    override init() {
        self.timestampID = Int64(NSDate().timeIntervalSince1970)
        super.init()
        NSLog("DataCollector: created instance")
    }
    
    deinit {
        // - Store files here
        
        // Assign tracks to votes
        for n in 0..<votes.count {
            votes[n].track = tracks[n][0]
        }
        
        if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            
            let votesFile = "\(timestampID)g.csv"
            let votesPath = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(votesFile)
            var output = "File,Grade,Track\n"
            for v in votes {
                output += "\(v.file),\(v.grade),\(v.track)\n" // Timestamp in v.track is rounded to 0.00001 (5 digits)
            }
            //(votes as NSArray).writeToURL(votesPath, atomically: false) // TODO: Try use struct over tuple
            do {
                try output.writeToURL(votesPath!, atomically: false, encoding: NSUTF8StringEncoding)
            }
            catch { }

            let trackFile = "\(timestampID)t.xml"
            let trackPath = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(trackFile)
            (tracks as NSArray).writeToURL(trackPath!, atomically: false)
            
            NSLog("Data written to \(votesFile), \(trackFile)")
        }
        
    }
    
    func addVote(file: String, _ vote: ACRGrade) {
        votes.append(Vote(file: file, grade: vote.rawValue, track: 0))
    }
    func startTracking() {
        guard !isTracking else {
            return
        }
        isTracking = true
    }
    func stopTracking() {
        guard isTracking else {
            return
        }
        tracks.append(track)
        track = []
        isTracking = false
    }
    func addPosition(timestamp: Double, horiz: Double, vert: Double, roll: Double) {
        guard isTracking else {
            return
        }
        track.appendContentsOf([timestamp,horiz,vert,roll])
    }
}
