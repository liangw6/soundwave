//
//  PlaySound.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/15/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//
//  Most of code in this file is modified based on Apple's Signal Generator tutorial
//  for WWDC 2019 (https://developer.apple.com/documentation/avfoundation/audio_track_engineering/building_a_signal_generator)

import Foundation
import AVFoundation

//var audioPlayer: AVAudioPlayer?


let twoPi = 2 * Float.pi

let sine = { (phase: Float) -> Float in
    return sin(phase)
}

let whiteNoise = { (phase: Float) -> Float in
    return ((Float(arc4random_uniform(UINT32_MAX)) / Float(UINT32_MAX)) * 2 - 1)
}

let sawtoothUp = { (phase: Float) -> Float in
    return 1.0 - 2.0 * (phase * (1.0 / twoPi))
}

let sawtoothDown = { (phase: Float) -> Float in
    return (2.0 * (phase * (1.0 / twoPi))) - 1.0
}

let square = { (phase: Float) -> Float in
    if phase <= Float.pi {
        return 1.0
    } else {
        return -1.0
    }
}

let triangle = { (phase: Float) -> Float in
    var value = (2.0 * (phase * (1.0 / twoPi))) - 1.0
    if value < 0.0 {
        value = -value
    }
    return 2.0 * (value - 0.5)
}

func playSignalSound(_ sampleRate: Float, frequency: Float = 440, amplitude: Float = 1.0, duration: Float = 5.0) -> AVAudioSourceNode {
    
    if amplitude > 1.0 || amplitude < 0.0 {
        print("Bad amplitude that is out of range of [0.0, 1.0]: ", amplitude.description)
        exit(1)
    }

    var signal: (Float) -> Float
    signal = sine

    var currentPhase: Float = 0
    // The interval by which we advance the phase each frame.
    let phaseIncrement = (twoPi / sampleRate) * frequency

    let srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for frame in 0..<Int(frameCount) {
            // Get signal value for this frame at time.
            let value = signal(currentPhase) * amplitude
            // Advance the phase for the next frame.
            currentPhase += phaseIncrement
            if currentPhase >= twoPi {
                currentPhase -= twoPi
            }
            if currentPhase < 0.0 {
                currentPhase += twoPi
            }
            // Set the same value on all channels (due to the inputFormat we have only 1 channel though).
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = value
            }
        }
        return noErr
    }

    return srcNode
}
