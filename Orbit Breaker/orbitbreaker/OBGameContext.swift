//
//  OBGameContext.swift
//  Orbit Breaker
//
//  Created by Sam Richard on 12/20/24.
//


import Combine
import GameplayKit

class OBGameContext: GameContext {
    var gameScene: OBGameScene? {
        scene as? OBGameScene
    }
    let gameMode: GameModeType
    var layoutInfo: OBLayoutInfo
    
    private(set) var stateMachine: GKStateMachine?
    
    init(dependencies: Dependencies, gameMode: GameModeType) {
        
        self.gameMode = gameMode
        self.layoutInfo = OBLayoutInfo(screenSize: UIScreen.main.bounds.size)
        super.init(dependencies: dependencies)
        
        self.scene = OBGameScene(context: self, size: UIScreen.main.bounds.size)
        
    }
    
}
