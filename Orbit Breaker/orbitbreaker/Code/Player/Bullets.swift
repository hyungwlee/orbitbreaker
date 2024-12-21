//
//  Bullets.swift
//  Orbit Breaker
//
//  Created by Thomas Rife on 11/6/24.
//

import SpriteKit

class Bullet: SKSpriteNode {
    var damage: Int
    
    init(damage: Int, texture: SKTexture? = SKTexture(imageNamed: "playerBullet"), size: CGSize, scaleFactor: CGFloat) {
        self.damage = damage
        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        super.init(texture: texture, color: .clear, size: scaledSize)

        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask =
        0x1 << 1 // Bullet category
        self.physicsBody?.contactTestBitMask = 0x1 << 2 // Enemy category
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

