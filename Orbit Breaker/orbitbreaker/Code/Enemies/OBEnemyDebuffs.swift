//
//  OBEnemyDebuffs.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//

import SpriteKit

enum OBDebuffType: CaseIterable {
    case freeze
    
}

class OBDebuffs: SKSpriteNode {
    let type: OBDebuffType
    
    init(type: OBDebuffType, color: UIColor, size: CGSize) {
        self.type = type
        
        super.init(texture: nil, color: color, size: size)
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask = 0x1 << 1
        self.physicsBody?.contactTestBitMask = 0x1 << 2
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.name = "debuffs"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(to enemy: OBEnemy) {
        switch type {
        case .freeze:
  //          enemy.applyFreezeDebuff(to: [enemy])
            print("NOT WORKING")
        }
    }
}
