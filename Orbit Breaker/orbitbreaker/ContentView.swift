//
//  GameViewController.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//
import SwiftUI
import SpriteKit

struct ContentView: View {
    let context = OBGameContext(dependencies: .init(), gameMode: .single)
    
    var body: some View {
        ZStack {
            SpriteView(scene: context.scene!, debugOptions: [.showsFPS, .showsNodeCount])
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .edgesIgnoringSafeArea(.all)
        }
        .statusBarHidden()
    }
}

#Preview {
    ContentView()
        .ignoresSafeArea()
}
