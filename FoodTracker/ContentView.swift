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
    
    // main classifier strategy: use two buffers to monitor left side and right side of the peak
    @State var leftResultBuffer: ResultBuffer = ResultBuffer(life_span: 7, pass_threshold_count: 4, threshold: 1.2)
    @State var rightResultBuffer: ResultBuffer = ResultBuffer(life_span: 7, pass_threshold_count: 4, threshold: 1.1)
    
    // This is fixed for 44.1 khz sample rate and 2048 values for each FFT
    let frequencyBuffer = ["17.85", "17.87", "17.89", "17.92", "17.94", "17.96", "17.98", "18.00", "18.02", "18.04", "18.07", "18.09", "18.11", "18.13", "18.15"]
    @State var magnitudeBuffer = [Float] (repeating: 0, count: 15)
    
    var body: some View {
        VStack {
            Button(action: {
//                print("button was tapped")
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
                
//                print("input sample rate \(inputFormat.sampleRate)")
//                print("output sample rate \(output.outputFormat(forBus: 0).sampleRate)")
                assert(inputFormat.sampleRate == 44100)
                assert(output.outputFormat(forBus: 0).sampleRate == 44100)
                
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
        self.magnitudeBuffer = self.simpleFFT.runFFTonSignal(samples)
        
        self.leftResultBuffer.addNewResult(Array(self.magnitudeBuffer[0...6]))
        self.rightResultBuffer.addNewResult(Array(self.magnitudeBuffer[8...14]))
        
        if self.leftResultBuffer.passThreshold() {
            self.pushOrPullState = "Pull"
        } else if self.rightResultBuffer.passThreshold() {
            self.pushOrPullState = "Push"
        } else {
            self.pushOrPullState = "None"
        }

    }
    
    func endRecording() {
        self.engine.stop()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
