//
//  Enemy.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit

class Enemy: SKSpriteNode {
    private(set) var health: Int
    let initialHealth: Int
    private var nextShootTime: TimeInterval = 0
    var canShoot: Bool  // Only some enemies will be able to shoot
    
    init(type: EnemyType) {
        self.initialHealth = type.initialHealth
        self.health = type.initialHealth
        
        // Only about 20% of enemies can shoot initially
        self.canShoot = Double.random(in: 0...1) < 0.2
        
        super.init(texture: nil, color: type.color, size: EnemyType.size)
        self.name = EnemyType.name
        
        // Setup physics for collision detection
        self.physicsBody = SKPhysicsBody(rectangleOf: EnemyType.size)
        self.physicsBody?.categoryBitMask = 0x1 << 2
        self.physicsBody?.contactTestBitMask = 0x1 << 1
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.isDynamic = false
        
        if canShoot {
            // Randomize initial shoot time more significantly
            self.nextShootTime = Double.random(in: 1...5)  // First shot between 1-5 seconds
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateShooting(currentTime: TimeInterval, scene: SKScene, waveNumber: Int) {
        guard canShoot else { return }
        
        if currentTime >= nextShootTime {
            shoot(scene: scene)
            
            // Calculate next shoot time based on wave number
            // Starts at ~5 seconds between shots and decreases to ~2 seconds by wave 10
            let baseInterval = max(2.0, 5.0 - (Double(waveNumber) * 0.3))
            let randomVariation = Double.random(in: -0.5...0.5)  // Add some randomness
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
        
        // Slower bullet movement
        let moveAction = SKAction.moveBy(x: 0, y: -scene.size.height - bullet.size.height, duration: 2.0)  // Increased from 1.5 to 2.0
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func takeDamage(_ amount: Int) -> Bool {
        health -= amount
        
        run(SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.colorize(with: self.color, colorBlendFactor: 1.0, duration: 0.1)
        ]))
        
        return health <= 0
    }
}
