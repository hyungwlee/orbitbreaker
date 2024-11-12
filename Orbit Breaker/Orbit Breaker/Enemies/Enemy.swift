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
    var holdsPowerUp: Bool
    
    init(type: EnemyType) {
            // Set health based on enemy type
            self.initialHealth = type.initialHealth
            self.health = type.initialHealth
            self.canShoot = false
            self.holdsPowerUp = false
            
            // Load the enemy animation frames
            let textureAtlas = SKTextureAtlas(named: "Enemy")
            var frames: [SKTexture] = []
            
            // Assuming your gif frames are named "enemy_0", "enemy_1", "enemy_2", etc.
            // Adjust the range based on your number of frames
            for i in 0..<textureAtlas.textureNames.count {
                let textureName = "enemy_\(i)"
                frames.append(textureAtlas.textureNamed(textureName))
            }
            
            // Initialize with the first frame
            let doubledSize = CGSize(width: EnemyType.size.width * 2, height: EnemyType.size.height * 3)
            super.init(texture: frames[0], color: .white, size: doubledSize)
            
            // Create the animation action
            let animateAction = SKAction.animate(with: frames,
                                                 timePerFrame: 0.15, // Adjust timing as needed
                                               resize: false,
                                               restore: true)
            let repeatForever = SKAction.repeatForever(animateAction)
            
            // Run the animation
            self.run(repeatForever)
                
            // Set initial rotation (facing right)
            self.zRotation = 0
            
            // Set the color blend to tint the sprite
            self.colorBlendFactor = 1.0
            
            // Create circular physics body
            self.physicsBody = SKPhysicsBody(circleOfRadius: EnemyType.size.width)
            self.physicsBody?.categoryBitMask = 0x1 << 2
            self.physicsBody?.contactTestBitMask = 0x1 << 1
            self.physicsBody?.collisionBitMask = 0
            self.physicsBody?.affectedByGravity = false
            self.physicsBody?.isDynamic = true
            
            // Don't allow physics to affect rotation
            self.physicsBody?.allowsRotation = false
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
    
    func dropPowerUp(scene: SKScene) {
        if (self.holdsPowerUp) {
            let powerUpType = PowerUps.allCases.randomElement()!
            let powerUp = PowerUp(type: powerUpType, color: .green, size: CGSize(width: 10, height: 10))
            print("dropped powerup of type \(powerUp.type)")
            
            powerUp.name = "powerUp"
            powerUp.position = CGPoint(x: position.x, y: position.y - size.height/2)
            
            powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.size)
            powerUp.physicsBody?.categoryBitMask = 0x1 << 3
            powerUp.physicsBody?.contactTestBitMask = 0x1 << 0
            powerUp.physicsBody?.collisionBitMask = 0
            powerUp.physicsBody?.affectedByGravity = false
            
            scene.addChild(powerUp)
            
            // Ensure powerUps travel full screen height
            let moveAction = SKAction.moveBy(x: 0, y: -(scene.size.height + powerUp.size.height), duration: 6.5)
            let removeAction = SKAction.removeFromParent()
            powerUp.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    
    func takeDamage(_ amount: Int) -> Bool {
        health -= amount
        print("Enemy took \(amount) damage. Health now: \(health)")  // Debug print
        
        let isDead = (health <= 0)
        
        if isDead {
            return isDead
        }
        
        // Update enemy color based on health
        self.color = EnemyType.colorForHealth(health)
        
        // Flash effect
        self.run(SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.colorize(with: EnemyType.colorForHealth(health), colorBlendFactor: 1.0, duration: 0.1)
        ]))
        
        return false
    }
}

