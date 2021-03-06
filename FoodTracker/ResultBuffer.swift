//
//  ResultBuffer.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/22/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//
//  ResultBuffer keeps track of a few most recent results and how many of those results have passed the threshold
//  It uses a different approach from the original soudwave paper in that it uses mostly time information to do classification, e.g. over
//  the past 7 samples, how many of them are above threshold.
//  In contrast, the paper finds the peak at each time interval, with little time relevance used.
//  Using time information helps to provide a smoother classification result and is necessary when the second peak is hardly visible
//  or highly variable in case of different volumes on user device.

import Foundation

class ResultBuffer {
    
    var life_span: Int
    var threshold: Float
    var pass_thre_count: [Int]
    var count: Int // how many times addNewResult has been called
    var ignore_first_n: Int // ignore the first few becuase the sliding window is not ready yet
    var pass_threshold_count: Int  // how many items passed the threshold
    var prev_result = [Float](repeating: 1.0, count: 7)  // cache copy of previous result to compare to
    
    init(life_span: Int, pass_threshold_count: Int, threshold: Float) {
        self.life_span = life_span
        self.threshold = threshold
        self.pass_thre_count = []
        self.count = 0
        self.ignore_first_n = life_span
        self.pass_threshold_count = pass_threshold_count
    }
    
    func addNewResult(_ results: [Float]) {
//        print(prev_result)
//        print(results)
//        print()
        
        // all lifespan - 1
        if self.count >= self.ignore_first_n {
            self.pass_thre_count = self.pass_thre_count.map({(curr) -> Int in
                    return curr - 1
            }).filter {
                return $0 > 0
            }
        }
        self.count += 1
        for result in results.enumerated() {
            if (result.element / prev_result[result.offset] >= threshold) {
                self.pass_thre_count.append(self.life_span)
                break
            }
        }
        self.prev_result = results
    }
    
    func passThreshold() -> Bool {
        return self.pass_thre_count.count > self.pass_threshold_count
    }
}

