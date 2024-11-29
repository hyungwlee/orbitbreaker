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
    var initialHealth: Int
    private var nextShootTime: TimeInterval = 0
    var canShoot: Bool
    var holdsPowerUp: Bool
    var holdsDebuff: Bool
    
    init(type: EnemyType) {
        self.initialHealth = type.initialHealth
        self.health = type.initialHealth
        self.canShoot = false
        self.holdsPowerUp = false
        self.holdsDebuff = false
        
        super.init(texture: SKTexture(imageNamed: "enemy"), color: .white,
                   size: CGSize(width: EnemyType.size.width * 2, height: EnemyType.size.height * 2.3))
        
        self.zPosition = 1
        self.zRotation = 0
        self.colorBlendFactor = 1.0
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: EnemyType.size.width)
        self.physicsBody?.categoryBitMask = 0x1 << 2
        self.physicsBody?.contactTestBitMask = 0x1 << 1
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.isDynamic = true
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
    
    func dropDebuff(scene: SKScene) {
        if self.holdsDebuff {
            let debuffType = DebuffType.freeze
            let debuff = Debuffs(type: debuffType, color: .purple, size: CGSize(width: 10, height: 10))
            print("Dropped debuff of type \(debuff.type)")
            
            debuff.name = "debuff"
            debuff.position = CGPoint(x: position.x, y: position.y - size.height / 2)
            
            debuff.physicsBody = SKPhysicsBody(rectangleOf: debuff.size)
            debuff.physicsBody?.categoryBitMask = 0x1 << 4 // Use a unique bitmask for debuffs
            debuff.physicsBody?.contactTestBitMask = 0x1 << 0 // Player category
            debuff.physicsBody?.collisionBitMask = 0
            debuff.physicsBody?.affectedByGravity = false

            scene.addChild(debuff)
            
            let moveAction = SKAction.moveBy(x: 0, y: -(scene.size.height + debuff.size.height), duration: 6.5)
            
            let removeAction = SKAction.removeFromParent()
            debuff.run(SKAction.sequence([moveAction, removeAction]))
        }
    }

    
    func applyFreezeDebuff(to enemies: [Enemy]) {
        for enemy in enemies {
            enemy.canShoot = false
        }


            
        
    }
}

