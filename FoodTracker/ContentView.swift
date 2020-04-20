//
//  ContentView.swift
//  FoodTracker
//
//  Created by Liang Arthur on 4/15/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    
    @ObservedObject var pushOrPull = PushAndPullClassifier()
    
    var body: some View {
        VStack {
            Button(action: {
                print("button was tapped")
                DispatchQueue.main.async() {
                    playSound(sound: "bell_sound", type: "wav")
                }
                self.pushOrPull.startRecording()
            }) {
                Text("Emit Sound")
            }
            Text("")
            Text("\(self.pushOrPull.pushOrPullState)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
