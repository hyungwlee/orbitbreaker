//
//  GameViewController.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import UIKit
import SpriteKit
import GameplayKit

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let skView = SKView(frame: self.view.frame)
        self.view = skView
        
        let dependencies = Dependencies() // Replace with actual dependencies
        let gameContext = GameContext(dependencies: dependencies)
        let screenSize = UIScreen.main.bounds.size
        gameContext.updateLayoutInfo(withScreenSize: screenSize)
        
        let scene = GameScene(size: skView.frame.size)
        scene.context = gameContext
        scene.scaleMode = .aspectFill
        
        
        skView.presentScene(scene)
        
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}