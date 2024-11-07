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
    public var fireRate: TimeInterval = 0.15  // Made variable to change fire rate
    private var isDragging = false
    private var canShoot = true  // New property to control shooting
    private var shield: SKSpriteNode?
    var hasShield: Bool = false
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
        // bullet damage gets multiplied by damage multiplier (either 0 or 1 depending on power up status)
        let bulletdamage: Int = 10 * damageMultiplier
        
        // Create new bullet with damage criteria from above
        let bullet = Bullet(damage: bulletdamage, color: .yellow, size: CGSize(width: 4, height: 10))
        
        // set bullet position
        bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.size.height/2)
        bullet.name = "testBullet"
        
        // adds bullet to ship
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
    
    // adding shield function, creates a blue box, not sure how it looks yet I haven't run this part
    func addShield() {
        
        // checks if shield exists, then if not and the function is called, it creates a new shield around the ship
        hasShield = true
        if shield == nil {
            let shield = SKShapeNode(circleOfRadius: 50)
            shield.strokeColor = .clear
            shield.fillColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.3)
            shield.position = CGPoint(x: 0, y: 0)
            
            // adds shield to the ship
            ship.addChild(shield)
        }
    }
    
    // when called, the shield is removed and set to nil as to not interfere with previous function
    func removeShield() {
        hasShield = false
        shield?.removeFromParent()
        shield = nil
    }
    
    // removes ship from screen
    func cleanup() {
        ship.removeFromParent()
    }
}
