//
//  ContentView.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/15/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import SwiftUI
import AVFoundation
import Accelerate

struct ContentView: View {
    
    let engine = AVAudioEngine()
    var simpleFFT: SimpleFFT = SimpleFFT()
    @State var pushOrPullState: String = "Calculating"
    
    @State var count = 0
    
    @State var leftResultBuffer: ResultBuffer = ResultBuffer(life_span: 5, passThresholdCount: 3, threshold: 1.92)
    @State var rightResultBuffer: ResultBuffer = ResultBuffer(life_span: 5, passThresholdCount: 3, threshold: 2.4)
    
    @State var leftValue: Float = 0
    @State var midValue: Float = 0
    @State var rightValue: Float = 0
    
    
    var body: some View {
        VStack {
            Button(action: {
                print("button was tapped")
//                DispatchQueue.main.async() {
//                    playSignalSound(frequency: 18000, amplitude: 1.0, duration: 1)
//                }

                // set up engine for the FFT recording
                let input = self.engine.inputNode
                let bus = 0
                let inputFormat = input.inputFormat(forBus: bus)
                // the most recent samples that we are keeping in the circular buffer
                // Here is the last 5 sec
                self.simpleFFT.set_sample_rate(inputFormat.sampleRate) // AVAudioFrameCount(inputFormat.sampleRate * 5)
                input.installTap(onBus: bus, bufferSize: 2048, format: inputFormat) { (buffer, time) -> Void in
                    buffer.frameLength = 2048
                    self.gotSomeAudio(buffer)
                }
                // set up engine for source node
                let output = self.engine.outputNode
                let srcNode = playSignalSound(Float(output.outputFormat(forBus: 0).sampleRate), frequency: 18000)
                self.engine.attach(srcNode)
                self.engine.connect(srcNode, to: output, format: inputFormat)
                
                print("input sample rate \(inputFormat.sampleRate)")
                print("output sample rate \(output.outputFormat(forBus: 0).sampleRate)")
                
                // start the engine
                // which should start recording and signal generation
                do {
                    try self.engine.start()
                } catch {
                    print("Could not start engine: \(error)")
                    return
                }
                
                // start the recording
                print("starting")

                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("stopping")
                    self.endRecording()
                }
            }) {
                Text("Emit Sound")
            }
            Text("")
            Text("\(self.pushOrPullState)")
            Text("")
            Text("")
            Text("Left Side: \(self.leftValue)")
            Text("Peak:      \(self.midValue)")
            Text("Right Side: \(self.rightValue)")
        }
    }
    
    func gotSomeAudio(_ buffer: AVAudioPCMBuffer) {
        var samples:[Float] = []
//        print("framelength \(buffer.frameLength)")
        for i in 0 ..< 2048
        {
            let theSample = (buffer.floatChannelData?.pointee[i])!
            samples.append(theSample)
        }
//        print("input framelength \(samples.count)")
        self.count = self.count + 1
        let highlight_mag = self.simpleFFT.runFFTonSignal(samples)
        
        self.leftValue = highlight_mag[0] / highlight_mag[1]
        self.midValue = highlight_mag[1]
        self.rightValue = highlight_mag[2] / highlight_mag[1]
        
        self.leftResultBuffer.addNewResult(self.leftValue)
        self.rightResultBuffer.addNewResult(self.rightValue)
        
        if self.leftResultBuffer.passThreshold() {
            self.pushOrPullState = "Pull"
        } else if self.rightResultBuffer.passThreshold() {
            self.pushOrPullState = "Push"
        } else {
            self.pushOrPullState = "None"
        }

//        print("Left Side: \(self.leftValue)")
////        print("Peak:      \(self.midValue)")
//        print("Right Side: \(self.rightValue)")
    }
    
    func endRecording() {
        print("total \(self.count)")
        self.engine.stop()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
