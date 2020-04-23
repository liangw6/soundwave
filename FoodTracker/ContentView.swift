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
import CoreGraphics

struct ContentView: View {
    
    let engine = AVAudioEngine()
    var simpleFFT: SimpleFFT = SimpleFFT()
    @State var pushOrPullState: String = "None"
    
    @State var count = 0
    
    @State var leftResultBuffer: ResultBuffer = ResultBuffer(life_span: 7, pass_threshold_count: 4, threshold: 1.2)
    @State var rightResultBuffer: ResultBuffer = ResultBuffer(life_span: 7, pass_threshold_count: 4, threshold: 1.1)
    
    @State var leftValue: Float = 0
    @State var midValue: Float = 0
    @State var rightValue: Float = 0
    
    let frequencyBuffer = ["17.85", "17.87", "17.89", "17.92", "17.94", "17.96", "17.98", "18.00", "18.02", "18.04", "18.07", "18.09", "18.11", "18.13", "18.15"]
    @State var magnitudeBuffer = [Float] (repeating: 0, count: 15)
    
    
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

                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    print("stopping")
                    self.endRecording()
                }
            }) {
                Text("Emit Sound")
            }
            Text("")
            Text("\(self.pushOrPullState)")
//            Text("")
//            Text("")
//            Spacer().frame(height: 500)
//            Text("Left Side: \(self.leftValue)")
//            Text("Peak:      \(self.midValue)")
//            Text("Right Side: \(self.rightValue)")
            VStack {
                HStack {
                  // 2
                  ForEach(0..<15) { i in
                    // 3
                    VStack {
                      // 4
    //                  Spacer()
                      // 5
                      Rectangle()
                        .fill(Color.green)
                        .frame(width: 20, height: CGFloat(self.magnitudeBuffer[i]) * 10)
                      // 6
                      Text("\(self.frequencyBuffer[i])")
                        .font(.footnote)
                        .frame(height: 20)
                    }
                  }
                }
                Text("kHz")
            }.offset(y: 300)
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
        self.magnitudeBuffer = self.simpleFFT.runFFTonSignal(samples)
        
        print("left")
        self.leftResultBuffer.addNewResult(Array(self.magnitudeBuffer[0...6]))
        print("right")
        self.rightResultBuffer.addNewResult(Array(self.magnitudeBuffer[8...14]))
        
//        let highlight_mag = self.simpleFFT.runFFTonSignal(samples)
//
//        self.leftValue = highlight_mag[0] / highlight_mag[1]
//        self.midValue = highlight_mag[1]
//        self.rightValue = highlight_mag[2] / highlight_mag[1]
//
//        self.leftResultBuffer.addNewResult(self.leftValue)
//        self.rightResultBuffer.addNewResult(self.rightValue)
//
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
