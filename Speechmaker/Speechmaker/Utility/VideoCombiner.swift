//
//  VideoCombiner.swift
//  SpeechmakerCLI
//
//  Created by Ethan Diamond on 7/31/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import AVFoundation
import UIKit

private let WATERMARK_HEIGHT: CGFloat = 50.0
private let WATERMARK_WIDTH: CGFloat = 300.0
private let SHORT_VIDEO_SNIP = CMTimeMake(1, 60)
private let LONG_VIDEO_SNIP = CMTimeMake(2, 60)

class VideoCombiner {
    var exporter: AVAssetExportSession? = nil
    
    func combineVideos(_ urls: [URL], outputPath: String, progress: ((_ progress: Float) -> ())?, complete: @escaping () -> ()) {
        log("Beginning combine video")
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey : true]
        let assets = urls.map { (url) -> AVAsset in AVURLAsset(url: url, options: options)}
        
        // Create the tracks
        let mixComposition = AVMutableComposition()
        let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // Stitch the assets
        for asset in assets {
            let currentTime = mixComposition.duration
            
            let videoAssetTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first!
            let audioAssetTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first!
            
            var timeRange = videoAssetTrack.timeRange.duration < audioAssetTrack.timeRange.duration ? videoAssetTrack.timeRange : audioAssetTrack.timeRange
            timeRange = shaveTimeRange(timeRange, byTime: SHORT_VIDEO_SNIP)
            
            try! videoTrack.insertTimeRange(timeRange,
                                            of: videoAssetTrack,
                                            at: currentTime)
            
            try! audioTrack.insertTimeRange(timeRange,
                                            of: audioAssetTrack,
                                            at: currentTime)
        }
        
        // Clear the old video
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputPath) {
            try! fileManager.removeItem(atPath: outputPath)
        }
        
        // Create the exporter
        exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetPassthrough)!
        exporter!.outputURL = URL(fileURLWithPath: outputPath)
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.canPerformMultiplePassesOverSourceMediaData = true
        exporter!.timeRange = shaveTimeRange(videoTrack.timeRange, byTime: LONG_VIDEO_SNIP)
        
        if (progress != nil) {
            updateProgress(progress!)
        }
        
        // Export
        exporter!.exportAsynchronously() {
            dispatch_main {
                progress?(1.0) // Exporter doesn't necessarily hit 100%
                log("Completed combine video")
                complete()
            }
        }
    }
    
    fileprivate func updateProgress(_ progress: @escaping (_ progress: Float) -> ()) {
        delay(0.05) {
            dispatch_main {
                progress(self.exporter!.progress)
            }
            
            if (self.exporter?.status != .failed && self.exporter?.status != .completed) {
                self.updateProgress(progress)
            }
        }
    }
    
    // We need to shave a few frames to prevent the black frames unless we're on iOS 10
    fileprivate func shaveTimeRange(_ timeRange: CMTimeRange, byTime: CMTime) -> CMTimeRange {
        if ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 0, patchVersion: 0)) {
            return timeRange
        }
        
        return CMTimeRangeMake(CMTimeAdd(timeRange.start, byTime), CMTimeSubtract(timeRange.duration, CMTimeMultiply(byTime, 2)))
    }
}
