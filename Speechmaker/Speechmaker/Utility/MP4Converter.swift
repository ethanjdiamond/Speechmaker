//
//  MP4Converter.swift
//  SpeechmakerCLI
//
//  Created by Ethan Diamond on 7/31/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import AVFoundation
import UIKit

class MP4Converter {
    var exporter: SDAVAssetExportSession? = nil
    
    func convertVideo(_ url: URL, outputPath: String, progress: ((_ progress: Float) -> ())?, complete: @escaping () -> ()) {
        // Clear the old video
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputPath) {
            try! fileManager.removeItem(atPath: outputPath)
        }
        
        // Create the exporter
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey : true]
        exporter = SDAVAssetExportSession(asset: AVURLAsset(url: url, options: options))
        exporter!.outputURL = URL(fileURLWithPath: outputPath)
        exporter!.outputFileType = AVFileTypeMPEG4
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.videoSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: 720,
            AVVideoHeightKey: 720,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1024000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        ]
        exporter!.audioSettings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 96000,
        ]
        
        // Export
        exporter!.exportAsynchronously() {
            dispatch_main {
                progress?(1.0) // Exporter doesn't necessarily hit 100%
                log("Completed combine video")
                complete()
            }
        }
    }
}

