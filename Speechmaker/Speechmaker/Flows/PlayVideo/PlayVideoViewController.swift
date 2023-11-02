//
//  PlayVideoViewController.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/7/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import AVFoundation
import Crashlytics

class PlayVideoViewController: UIViewController, PlayerDelegate {
    
    @IBOutlet var playButton: UIImageView!
    
    var fragmentVideos: [FragmentVideo]!
    var videoDownloadManager: VideoDownloadManager!
    var videoLoadingViewController: VideoLoadingViewController!
    var socialViewController: SocialViewController!
    var player: Player!
    
    var shareAsset: AVURLAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        player.fillMode = AVLayerVideoGravityResizeAspectFill
        player.playbackLoops = true
        player.delegate = self
        
        socialViewController = UIStoryboard(name: "SocialViewController", bundle: nil).instantiateInitialViewController()
            as! SocialViewController
        view.addSubview(socialViewController.view)
        socialViewController.view.isHidden = true
        
        videoLoadingViewController = storyboard!.instantiateViewController(withIdentifier: "VideoLoadingViewController")
            as! VideoLoadingViewController
        view.addSubview(videoLoadingViewController.view)
        videoLoadingViewController.loadFragmentVideos(fragmentVideos, videoDownloadManager: videoDownloadManager, success: { [weak self] (outputPath, shareOutputPath) in
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] Create Video", customAttributes: ["speech" : self!.getSpeechText()])
            self?.player.setUrl(URL(fileURLWithPath: outputPath))
            self?.player.playFromBeginning()
            self?.shareAsset = AVURLAsset(url: URL(fileURLWithPath: shareOutputPath))
        }, failure: { [weak self] (fragmentVideo, error) in
            log(error.localizedDescription)
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] Create Video Failed", customAttributes: ["error" : error.localizedDescription, "speech" : self?.getSpeechText()])
            let _ = self?.navigationController?.popViewController(animated: true)
            UIAlertController.alert("There was an error downloading your video. Speechmaker was unable to find the word \"\(fragmentVideo.fragment.text!)\". Please try again.")
        })
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PlayVideoViewController.togglePlay))
        player.playerView.addGestureRecognizer(gestureRecognizer)
    }
    
    func togglePlay() {
        if (player.playbackState == .playing) {
            player.pause()
        } else {
            player.playFromCurrentTime()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "Player") {
            player = segue.destination as! Player
        }
    }
    
    @IBAction func facebookShareButtonWasTapped() {
        player.pause()
        let account = FacebookAccount()
        socialViewController.presentWithSocialAccount(account, video: shareAsset) {
            log("FACEBOOK FINISHED POSTING")
        }
    }
    
    @IBAction func twitterShareButtonWasTapped() {
        player.pause()
        let account = TwitterAccount()
        socialViewController.presentWithSocialAccount(account, video: shareAsset) {
            log("TWITTER FINISHED POSTING")
        }
    }
    
    @IBAction func otherShareButtonWasTapped() {
        player.pause()
        let activityViewController = UIActivityViewController(activityItems: [shareAsset.url], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityType.saveToCameraRoll]
        activityViewController.completionWithItemsHandler = { activityType, success, items, error in
            if error != nil {
                Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] Share Failed", customAttributes: ["error" : error?.localizedDescription, "type" : activityType?.rawValue])
                return
            }
            
            if !success{
                Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] Cancelled Share", customAttributes: ["type" : activityType?.rawValue])
                return
            }
            
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] Shared", customAttributes: ["type" : activityType?.rawValue])
        }
        navigationController?.present(activityViewController, animated: true) {}
    }
    
    @IBAction func backButtonWasTapped() {
        player = nil
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Mark: Player delegate
    
    func playerBufferingStateDidChange(_ player: Player) {}
    func playerReady(_ player: Player) {
        self.videoLoadingViewController.view.removeFromSuperview()
    }
    func playerPlaybackStateDidChange(_ player: Player) {
        if (player.playbackState == .playing) {
            playButton.isHidden = true
        } else {
            playButton.isHidden = false
        }
    }
    func playerCurrentTimeDidChange(_ player: Player) {}
    func playerPlaybackWillStartFromBeginning(_ player: Player) {}
    func playerPlaybackDidEnd(_ player: Player) {}
    
    // Mark: Convenience
    
    func getSpeechText() -> String {
        return fragmentVideos.map({ (fragmentVideo) -> String in
            fragmentVideo.fragment.text!
        }).joined(separator: " ")
    }
}
