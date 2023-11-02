//
//  LoadingViewController.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/13/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import MagicalRecord
import Crashlytics

let WORDS_TTL: TimeInterval = 24 * 60 * 60

class LoadingViewController: UIViewController {
    @IBOutlet var titleView: UIImageView!
    @IBOutlet var noInternetView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleView.shimmer()
        NotificationCenter.default.addObserver(self, selector: #selector(LoadingViewController.reachabilityStatusDidChange(_:)), name: ReachabilityChangedNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        initApp()
        updateVersion()
        updateWords()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initApp() {
        if (App.mr_findFirst() == nil) {
            MagicalRecord.save(blockAndWait: { (context) in
                let app = App.mr_createEntity(in: context)!
                app.installDate = Date()
                app.appVersion = AppVersion.currentVersion().stringValue
            })
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] App Install", customAttributes: ["version" : AppVersion.currentVersion().stringValue])
            log("Created app model")
        }
    }
    
    fileprivate func updateVersion() {
        let app = App.defaultApp()
        if (app.appVersion == nil || AppVersion(versionString: app.appVersion!) < AppVersion.currentVersion()) {
            MagicalRecord.save(blockAndWait: { (context) in
                let app = App.defaultAppInContext(context)
                app.appVersion = AppVersion.currentVersion().stringValue
            })
            
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] App Update", customAttributes: ["version" : AppVersion.currentVersion().stringValue])
            log("Updated app version")
        }
    }
    
    fileprivate func updateWords() {
        SpeechmakerService.instance.getFragments({ (words, pauses) in
            MagicalRecord.save(blockAndWait: { (context) in
                context.mr_deleteObjects(Fragment.mr_findAll(in: context)! as NSFastEnumeration)
                
                let appWords = words.map { word -> Word in
                    let appWord = Word.mr_createEntity(in: context)!
                    appWord.text = word
                    appWord.alphanumericText = word.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
                    return appWord
                }
                
                let appPauses = pauses.map { pause -> Pause in
                    let appPause = Pause.mr_createEntity(in: context)!
                    appPause.text = pause
                    return appPause
                }
                
                let app = App.defaultAppInContext(context)
                app.words = NSSet(array: appWords)
                app.pauses = NSSet(array: appPauses)
            })
            
            log("Updated fragments")
            self.completeLoading()
        }, failure: { (error) in
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] Fragment Download Failed", customAttributes: ["error" : error.localizedDescription])
            log("Failed update fragments: \(error)")
            delay(3, closure: {
                self.updateWords()
            })
        })
    }
    
    fileprivate func completeLoading() {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "SpeechCreatorViewController") as! SpeechCreatorViewController
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    @objc fileprivate func reachabilityStatusDidChange(_ notification: Notification?) {
        self.noInternetView.isHidden = Reachability.instance.isReachable
    }
}
