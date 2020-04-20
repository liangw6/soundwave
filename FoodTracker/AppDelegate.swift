//
//  AppDelegate.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/15/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
//            try audioSession.setMode(AVAudioSession.Mode.measurement)    // indicates that system will measure audio input or output
            try audioSession.setActive(true)
            // this will play the audio as if the phone is playing music, i.e. sound will come from both speakers (on top and on bottom)
            // not sure how this is going to affect the FFT but otherwise, the sound seems to have very low volume
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch {
            print("Can't Set Audio Session Category: \(error)")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

