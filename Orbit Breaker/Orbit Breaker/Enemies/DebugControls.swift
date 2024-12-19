//
//  DebugControls.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/6/24.
//

import SwiftUI

struct DebugControls: View {
    @Binding var isVisible: Bool
    var nextWave: () -> Void
    @State var currentWave = 1
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                if isVisible {
                    VStack {
                        Text("Wave: \(currentWave)")
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                        
                        Button(action: {
                            currentWave += 1
                            nextWave()
                        }) {
                            Text("Next Wave")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
