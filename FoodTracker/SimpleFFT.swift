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
import Accelerate

class SimpleFFT {
    // some constants for FFT
    let n = vDSP_Length(2048)
    lazy var log2n: vDSP_Length = vDSP_Length(log2(Float(n)))
    let halfN: Int = 1024
    
    var fftSetup: vDSP.FFT<DSPSplitComplex>!
    
    var sample_rate: Double = 48000
    
    init () {
        fftSetup = vDSP.FFT(log2n: log2n,
            radix: .radix2,
            ofType: DSPSplitComplex.self)
    }
    
    func set_sample_rate (_ sample_rate: Double) {
        self.sample_rate = sample_rate
    }
    
    func runFFTonSignal(_ signal: [Float]) {
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
                        print("output highilights")
                        vDSP.absolute(forwardOutput, result: &forwardOutputMagnitude)
                        
                        // filter out the low frequencies
                        let lowest_possible = Int(16000 * (Double(n) / sample_rate))
                        let highest_possible = halfN - 1
                        for magnitude in forwardOutputMagnitude[lowest_possible...highest_possible].enumerated() {
                            if magnitude.element > 1 {
                                print("\(Double(magnitude.offset + 1 + lowest_possible) * sample_rate / Double(n)) \(magnitude.element)")
                            }
                        }
                        print()
//                        let topMagnitudes = forwardOutputMagnitude.enumerated().filter {
//                            $0.element > 10
//                        }.map {
//                            return Double($0.offset + 1) * sample_rate / Double(n)
//                        }
//                        print(topMagnitudes)
                    }
                }
            }
        }
    }
    
//    func runFFTonSignal2(_ signal: [Float]) {
//        // As above, frameOfSamples = [1.0, 2.0, 3.0, 4.0]
//
//        let frameCount = frameOfSamples.count
//
//        let reals = UnsafeMutableBufferPointer<Float>.allocate(capacity: frameCount)
//        defer {reals.deallocate()}
//        let imags =  UnsafeMutableBufferPointer<Float>.allocate(capacity: frameCount)
//        defer {imags.deallocate()}
//        _ = reals.initialize(from: frameOfSamples)
//        imags.initialize(repeating: 0.0)
//        var complexBuffer = DSPSplitComplex(realp: reals.baseAddress!, imagp: imags.baseAddress!)
//
//        let log2Size = Int(log2(Float(frameCount)))
//        print(log2Size)
//
//        guard let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2Size), FFTRadix(kFFTRadix2)) else {
//            return []
//        }
//        defer {vDSP_destroy_fftsetup(fftSetup)}
//
//        // Perform a forward FFT
//        vDSP_fft_zip(fftSetup, &complexBuffer, 1, vDSP_Length(log2Size), FFTDirection(FFT_FORWARD))
//
//        let realFloats = Array(reals)
//        let imaginaryFloats = Array(imags)
//
//        print(realFloats)
//        print(imaginaryFloats)
//
//        return realFloats
//    }
}

