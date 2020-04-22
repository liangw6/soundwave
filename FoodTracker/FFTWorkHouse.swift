//
//  FFTWorkHouse.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/18/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import Foundation
import Accelerate

func FFTPlayGround() {
    let n = vDSP_Length(2048)

    let frequencies: [Float] = [1, 5, 25, 30, 75, 100,
                                300, 500, 512, 1023]

    // Create fake, composite signal
    let tau: Float = .pi * 2
    let signal: [Float] = (0 ... n).map { index in
        frequencies.reduce(0) { accumulator, frequency in
            let normalizedIndex = Float(index) / Float(n)
            return accumulator + sin(normalizedIndex * frequency * tau)
        }
    }

    // Setup FFT.
    // WARNING: This part is expensive!! Try doing it only once, e.g. during the startup of the app
    let log2n = vDSP_Length(log2(Float(n)))
    guard let fftSetUp = vDSP.FFT(log2n: log2n,
                                  radix: .radix2,
                                  ofType: DSPSplitComplex.self) else {
                                    fatalError("Can't create FFT Setup.")
    }
    
    let halfN = Int(n / 2)
            
    var forwardInputReal = [Float](repeating: 0,
                                   count: halfN)
    var forwardInputImag = [Float](repeating: 0,
                                   count: halfN)
    var forwardOutputReal = [Float](repeating: 0,
                                    count: halfN)
    var forwardOutputImag = [Float](repeating: 0,
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
                    fftSetUp.forward(input: forwardInput,
                                     output: &forwardOutput)
                }
            }
        }
    }
    
    

}
