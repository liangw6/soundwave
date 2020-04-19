//
//  PlaySound.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/15/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import Foundation
import AVFoundation

//var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
//    if let path = Bundle.main.path(forResource: sound, ofType: type) {
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
//            audioPlayer?.play()
//            print("playing sound~")
//        } catch {
//            print("could not find and play the sound file")
//        }
//    }
    playSignalSound()
}
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

func playSignalSound(signalName: String = "", frequency: Float = 440, amplitude: Float = 0.5, duration: Float = 5.0) {
//    let frequency = getFloatForKeyOrDefault(OptionNames.frequency, 440)
//    let amplitude = min(max(getFloatForKeyOrDefault(OptionNames.amplitude, 0.5), 0.0), 1.0)
//    amplitude = min(max(amplitude, 0.0), 1.0)
//    let duration = getFloatForKeyOrDefault(OptionNames.duration, 5.0)
//    let outputPath = userDefaults.string(forKey: OptionNames.output)
    
    if amplitude > 1.0 || amplitude < 0.0 {
        print("Bad amplitude that is out of range of [0.0, 1.0]: ", amplitude.description)
        exit(1)
    }

    var signal: (Float) -> Float

    if signalName != "" {
        let signalFunctions = ["sine": sine,
                               "noise": whiteNoise,
                               "square": square,
                               "sawtoothUp": sawtoothUp,
                               "sawtoothDown": sawtoothDown,
                               "triangle": triangle]

        if let signalFunction = signalFunctions[signalName] {
            signal = signalFunction
        } else {
            print("Please specify a valid signal type: \(signalFunctions.keys.sorted().joined(separator: ", "))")
            exit(1)
        }
    } else {
        signal = sine
    }

    let engine = AVAudioEngine()
    let mainMixer = engine.mainMixerNode
    let output = engine.outputNode
    let outputFormat = output.inputFormat(forBus: 0)
    let sampleRate = Float(outputFormat.sampleRate)
    // Use output format for input but reduce channel count to 1
    let inputFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                    sampleRate: outputFormat.sampleRate,
                                    channels: 1,
                                    interleaved: outputFormat.isInterleaved)

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

    engine.attach(srcNode)

    engine.connect(srcNode, to: mainMixer, format: inputFormat)
    engine.connect(mainMixer, to: output, format: outputFormat)
    mainMixer.outputVolume = 0.5

    do {
        try engine.start()

        // When writing the output file, the run loop will be stopped from the tap block
        // after the number of samples for the requested duration are written.
        // Otherwise, the run duration of the run loop is specified when started.
//        if outFile != nil {
//        CFRunLoopRun()
//        } else {
        CFRunLoopRunInMode(.defaultMode, CFTimeInterval(duration), false)
//        }
        engine.stop()
    } catch {
        print("Could not start engine: \(error)")
    }

}
