//
//  Enemy.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit
import SwiftUI

class Enemy: SKSpriteNode {
    var health: Int
        let initialHealth: Int
        private var nextShootTime: TimeInterval = 0
        var canShoot: Bool
        
        init(type: EnemyType) {
            // Set health based on enemy type
            self.initialHealth = type.initialHealth
            self.health = type.initialHealth
            self.canShoot = false
            
            super.init(texture: nil, color: type.color, size: EnemyType.size)
            
            // Clear the default sprite
            self.color = .clear
            
            // Add circle shape
            let circleShape = SKShapeNode(circleOfRadius: EnemyType.size.width / 2)
            circleShape.fillColor = type.color
            circleShape.strokeColor = SKColor.white
            circleShape.lineWidth = 2.0
            self.addChild(circleShape)
            
            // Create circular physics body
            self.physicsBody = SKPhysicsBody(circleOfRadius: EnemyType.size.width / 2)
            self.physicsBody?.categoryBitMask = 0x1 << 2
            self.physicsBody?.contactTestBitMask = 0x1 << 1  // Make sure this matches bullet category
            self.physicsBody?.collisionBitMask = 0
            self.physicsBody?.affectedByGravity = false
            self.physicsBody?.isDynamic = true  // Changed to true to enable proper collision detection
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    
    func updateShooting(currentTime: TimeInterval, scene: SKScene, waveNumber: Int) {
            guard canShoot else { return }
            
            if currentTime >= nextShootTime {
                shoot(scene: scene)
                
                // Add randomized delay between shots
                let baseInterval = 3.0  // Base 3 second interval
                let randomVariation = Double.random(in: -0.5...0.5)  // ±0.5 second variation
                nextShootTime = currentTime + baseInterval + randomVariation
            }
        }
        
        private func shoot(scene: SKScene) {
            let bullet = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 10))
            bullet.position = CGPoint(x: position.x, y: position.y - size.height/2)
            bullet.name = "enemyBullet"
            
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
            bullet.physicsBody?.categoryBitMask = 0x1 << 3
            bullet.physicsBody?.contactTestBitMask = 0x1 << 0
            bullet.physicsBody?.collisionBitMask = 0
            bullet.physicsBody?.affectedByGravity = false
            
            scene.addChild(bullet)
            
            // Ensure bullets travel full screen height
            let moveAction = SKAction.moveBy(x: 0, y: -(scene.size.height + bullet.size.height), duration: 2.0)
            let removeAction = SKAction.removeFromParent()
            bullet.run(SKAction.sequence([moveAction, removeAction]))
        }
        
    func takeDamage(_ amount: Int) -> Bool {
            health -= amount
            print("Enemy took \(amount) damage. Health now: \(health)")  // Debug print
           
            if let circleShape = self.children.first as? SKShapeNode {
                circleShape.fillColor = EnemyType.colorForHealth(health)
            }
            // Flash effect
            if let circleShape = self.children.first as? SKShapeNode {
                let currentColor = EnemyType.colorForHealth(health)
                circleShape.run(SKAction.sequence([
                    SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.1),
                    SKAction.colorize(with: currentColor, colorBlendFactor: 1.0, duration: 0.1)
                ]))
            }
            
            return health <= 0
        }
}



