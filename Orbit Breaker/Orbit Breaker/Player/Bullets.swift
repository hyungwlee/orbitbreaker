//
//  Bullets.swift
//  Orbit Breaker
//
//  Created by Thomas Rife on 11/6/24.
//

import SpriteKit

class Bullet: SKSpriteNode {
    var damage: Int
    // initializes damage class, takes three parameters damage, color and size
    init(damage: Int, color: UIColor, size: CGSize) {
        self.damage = damage
        super.init(texture: nil, color: color, size: size)
        
        // collision logic
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask = 0x1 << 1
        self.physicsBody?.contactTestBitMask = 0x1 << 2
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
