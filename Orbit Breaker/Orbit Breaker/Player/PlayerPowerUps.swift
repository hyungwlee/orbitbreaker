//
//  PowerUps.swift
//  Orbit Breaker
//
//  Created by Thomas Rife on 11/4/24.
//

import SpriteKit

enum PowerUps: CaseIterable {
    case shield
    case doubleDamage
}

class PowerUp: SKSpriteNode {
    let type: PowerUps
    
    init(type: PowerUps, color: UIColor, size: CGSize) {
        self.type = type
        
        super.init(texture: nil, color: color, size: size)
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask = 0x1 << 1
        self.physicsBody?.contactTestBitMask = 0x1 << 2
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.name = "powerUp"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(to player: Player) {
        switch type {
        case .shield:
            player.addShield()
            if let scene = scene as? GameScene {
                scene.powerUpManager.showPowerUp(.shield)
            }
        case .doubleDamage:
            player.setDoubleDamage()
            if let scene = scene as? GameScene {
                scene.powerUpManager.showPowerUp(.doubleDamage)
            }
        }
    }
}

