//
//  TestPlayer.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

// Player.swift

import SpriteKit

class Player {
    private weak var scene: SKScene?
    private var ship: SKSpriteNode
    private var lastFireTime: TimeInterval = 0
    public var fireRate: TimeInterval = 0.2  // Made variable to allow modification
    private var isDragging = false
    private var canShoot = true  // New property to control shooting
    private var shield: SKSpriteNode?
    public var damageMultiplier: Int = 1
    
    init(scene: SKScene) {
        self.scene = scene
        
        // Initialize ship
        //ship = SKSpriteNode(color: .white, size: CGSize(width: 30, height: 30))
        ship = SKSpriteNode(imageNamed: "Player")
        ship.size = CGSize(width: 80, height: 80)
        ship.position = CGPoint(x: scene.size.width/2, y: 60)
        ship.name = "testPlayer"
        
        // Add physics for enemy bullet collision
        //ship.physicsBody = SKPhysicsBody(rectangleOf: ship.size)
        ship.physicsBody = SKPhysicsBody(texture: ship.texture!, size: ship.size)
        ship.physicsBody?.categoryBitMask = 0x1 << 0     // Category 1
        ship.physicsBody?.contactTestBitMask = 0x1 << 3  // Will contact with category 4 (enemy bullets)
        ship.physicsBody?.collisionBitMask = 0
        ship.physicsBody?.affectedByGravity = false
        scene.addChild(ship)
    }
    
    func update(currentTime: TimeInterval) {
        if canShoot && currentTime - lastFireTime >= fireRate {
            fireBullet()
            lastFireTime = currentTime
        }
    }
    
    func fireBullet() {
        guard let scene = scene else { return }
        let bulletdamage: Int = 10 * damageMultiplier
        let bullet = Bullet(damage: bulletdamage, color: .yellow, size: CGSize(width: 4, height: 10))
        bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.size.height/2)
        bullet.name = "testBullet"
        
        scene.addChild(bullet)
        
        let moveAction = SKAction.moveBy(x: 0, y: scene.size.height + bullet.size.height, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }

    
    func handleTouch(_ touch: UITouch) {
        guard let scene = scene else { return }
        let location = touch.location(in: scene)
        
        // Handle ship movement
        let previousLocation = touch.previousLocation(in: scene)
        let deltaX = location.x - previousLocation.x
        let deltaY = location.y - previousLocation.y
        let newX = ship.position.x + deltaX
        let newY = ship.position.y + deltaY
        
        // Screen bounds checking
        let minX = ship.size.width/2
        let maxX = scene.size.width - ship.size.width/2
        let minY = ship.size.height/2
        let maxY = scene.size.width - ship.size.height/2
        ship.position.x = min(maxX, max(minX, newX))
        ship.position.y = min(maxY, max(minY, newY))
    }
    
    func addShield() {
        if shield == nil {
            let shield = SKSpriteNode(color: .blue, size: CGSize(width: 100, height: 100))
            shield.position = CGPoint(x: 0, y: 0)
            ship.addChild(shield)
        }
    }
    
    func removeShield() {
        shield?.removeFromParent()
        shield = nil
    }
    
    func cleanup() {
        ship.removeFromParent()
    }
}
