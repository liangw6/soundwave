//
//  PushAndPullClassifier.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/19/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//
//  The FFT component of this file is modified based on Apple's FFT tutorial
//  https://developer.apple.com/documentation/accelerate/finding_the_component_frequencies_in_a_composite_sine_wave

import Foundation
import AVFoundation
import SwiftUI
import Combine
import Accelerate

class SimpleFFT {
    // some constants for FFT
    let n = vDSP_Length(2048)
    lazy var log2n: vDSP_Length = vDSP_Length(log2(Float(n)))
    let halfN: Int = 1024
    
    var fftSetup: vDSP.FFT<DSPSplitComplex>!
    
    var sample_rate: Double = 48000
    
    let dividing_threashold = 16570
    
    init () {
        fftSetup = vDSP.FFT(log2n: log2n,
            radix: .radix2,
            ofType: DSPSplitComplex.self)
    }
    
    func set_sample_rate (_ sample_rate: Double) {
        self.sample_rate = sample_rate
    }
    
    // returns two arrays, frequencies and corresponding magnitudes
    func runFFTonSignal(_ signal: [Float]) -> [Float] {
        var forwardInputReal = [Float](repeating: 0,
                                       count: halfN)
        var forwardInputImag = [Float](repeating: 0,
                                       count: halfN)
        var forwardOutputReal = [Float](repeating: 0,
                                        count: halfN)
        var forwardOutputImag = [Float](repeating: 0,
                                        count: halfN)
        var forwardOutputMagnitude = [Float](repeating: 0,
                                        count: halfN)
        
        
        var highlights_mag = [Float](repeating: 0, count: 15)
//        var highlights_freq = [Float](repeating: 0, count: 15)
        
        forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
            forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                    forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                        
                        // 1: Create a `DSPSplitComplex` to contain the signal.
                        var forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!,
                                                           imagp: forwardInputImagPtr.baseAddress!)
                        
                        // 2: Convert the real values in `signal` to complex numbers.
                        signal.withUnsafeBytes {
                            vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),
                                         toSplitComplexVector: &forwardInput)
                        }
                        
                        // 3: Create a `DSPSplitComplex` to receive the FFT result.
                        var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                            imagp: forwardOutputImagPtr.baseAddress!)
                        
                        // 4: Perform the forward FFT.
                        self.fftSetup.forward(input: forwardInput,
                                         output: &forwardOutput)
                        
                        // calculate magnitude
//                        print("output highilights")
                        vDSP.absolute(forwardOutput, result: &forwardOutputMagnitude)
                        
//                        highlights_freq = [829, 830, 831, 832, 833, 834, 835, 836, 837, 838, 839, 840, 841, 842, 843]
                        highlights_mag = Array(forwardOutputMagnitude[829...843])
                        
                    }
                }
            }
        }
        return highlights_mag
    }
    
}

