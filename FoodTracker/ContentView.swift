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

                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    print("stopping")
                    self.endRecording()
                }
            }) {
                Text("Emit Sound")
            }
            Text("")
            Text("\(self.pushOrPullState)")
        }
    }
    
    func gotSomeAudio(_ buffer: AVAudioPCMBuffer) {
        var samples:[Float] = []
        print("framelength \(buffer.frameLength)")
        for i in 0 ..< 2048
        {
            let theSample = (buffer.floatChannelData?.pointee[i])!
            samples.append(theSample)
        }
        print("input framelength \(samples.count)")
        self.simpleFFT.runFFTonSignal(samples)
        self.count = self.count + 1
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
