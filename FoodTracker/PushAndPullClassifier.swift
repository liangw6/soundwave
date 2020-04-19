//
//  PushAndPullClassifier.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/19/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

class PushAndPullClassifier: ObservableObject {
    
    let engine = AVAudioEngine()
    var requiredSamples: AVAudioFrameCount = 0
    var ringBuffer: [AVAudioPCMBuffer] = []
    var ringBufferSizeInSamples: AVAudioFrameCount = 0
    
    @Published var pushOrPullState: String = "Calculating"
    
    init() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                // The user granted access. Present recording interface.
                print("permission granted")
            } else {
                // Present message to user indicating that recording
                // can't be performed until they change their preference
                // under Settings -> Privacy -> Microphone
                print("user said no :( ")
                exit(1)
            }
        }
        
        startRecording()
        print("recording in progress")

        DispatchQueue.main.asyncAfter(deadline: .now() + 4*60) {
            print("stopping")
            self.stopRecording()
        }
    }
    
    func startRecording() {
        let input = engine.inputNode

        let bus = 0
        let inputFormat = input.inputFormat(forBus: bus)

        requiredSamples = AVAudioFrameCount(inputFormat.sampleRate * 5)

        input.installTap(onBus: bus, bufferSize: 2048, format: inputFormat) { (buffer, time) -> Void in
            self.appendAudioBuffer(buffer)
        }

        try! engine.start()
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        ringBuffer.append(buffer)
        ringBufferSizeInSamples += buffer.frameLength

        // throw away old buffers if ring buffer gets too large
        if let firstBuffer = ringBuffer.first {
            if ringBufferSizeInSamples - firstBuffer.frameLength >= requiredSamples {
                // TODO: FFT Here
                DispatchQueue.main.async {
                    // force update at the main thread
                    self.pushOrPullState = "bufferFull"
                }
                ringBuffer.remove(at: 0)
                ringBufferSizeInSamples -= firstBuffer.frameLength
            }
        }
    }

    func stopRecording() {
        engine.stop()

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("foo.m4a")
        let settings: [String : Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC)]

        // write ring buffer to file.
        let file = try! AVAudioFile(forWriting: url, settings: settings)
        for buffer in ringBuffer {
            try! file.write(from: buffer)
        }
    }
    
}

