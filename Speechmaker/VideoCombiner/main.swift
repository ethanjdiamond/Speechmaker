//
//  main.swift
//  VideoCombiner
//
//  Created by Ethan Diamond on 7/31/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import Foundation
import AVFoundation

let baseFolder = "/Users/ejd33/Desktop/Speechmaker/"
let videoFolder = baseFolder + "videos/"
let fileManager = NSFileManager.defaultManager()

func getPathForWord(word: String) -> String? {
    let folderPath = videoFolder + word
    do {
        let files = try fileManager.contentsOfDirectoryAtPath(folderPath)
        return folderPath + "/" + files[0]
    } catch let error as NSError {
        print(error.localizedDescription)
    }
    
    return nil
}

let words = ["I'm", "the", "world's", "worst", "person"]
let wordPaths = words.map { (word) -> String in getPathForWord(word)!}
let wordAssets = wordPaths.map { (wordPath) -> AVAsset in AVURLAsset(URL: NSURL(fileURLWithPath: wordPath))}

let videoCombiner = VideoCombiner()

let semaphore = dispatch_semaphore_create(0);
videoCombiner.combineVideos(wordAssets, outputPath: baseFolder + "final.mp4") {
    dispatch_semaphore_signal(semaphore);
}
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

print("FINISHED")
