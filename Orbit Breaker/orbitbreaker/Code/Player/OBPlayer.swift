//
//  OBPlayer.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

// Player.swift

import SpriteKit

class OBPlayer {
    private weak var scene: SKScene?
    private var ship: SKSpriteNode
    private var lastFireTime: TimeInterval = 0
    public var fireRate: TimeInterval = 0.1  // Made variable to change fire rate
    private var isDragging = false
    private var shieldNode: SKShapeNode?
    var hasShield: Bool = false
    public var damageMultiplier: Int = 1
    private var shieldTimer: Timer?
    private var damageTimer: Timer?
    var canShoot: Bool = true
    var scaleFactor: CGFloat
    var layoutInfo: OBLayoutInfo // Store the layoutInfo to access screenScaleFactor

    init(scene: SKScene, layoutInfo: OBLayoutInfo) {
        self.scene = scene
        self.scaleFactor = 1.5
        self.layoutInfo = layoutInfo // Store layoutInfo for access to screenScaleFactor

        // Use size and position from LayoutInfo
        ship = SKSpriteNode(imageNamed: "Player")
        // let scaleFactor: CGFloat = 1.5 // Adjust this to fine-tune the size
        ship.size = CGSize(width: layoutInfo.nodeSize.width * scaleFactor,
                           height: layoutInfo.nodeSize.height * scaleFactor)
        
        let scalePosition: CGFloat = 0.3
        ship.position = CGPoint(x: layoutInfo.nodePosition.x, y: layoutInfo.nodePosition.y * scalePosition)
        
        ship.name = "testPlayer"
        
        
        // Add physics for enemy bullet collision
        //ship.physicsBody = SKPhysicsBody(rectangleOf: ship.size)
        ship.physicsBody = SKPhysicsBody(texture: ship.texture!, size: ship.size)
        ship.physicsBody?.categoryBitMask = 0x1 << 0        // Category 0 (Player)
        ship.physicsBody?.contactTestBitMask = 0x1 << 2 |   // Enemy (Category 2)
        0x1 << 3 |      // Enemy bullets (Category 3)
        0x1 << 4        // Boss (Category 4)
        ship.physicsBody?.collisionBitMask = 0
        ship.physicsBody?.affectedByGravity = false
        scene.addChild(ship)
    }
    
    func playSoundEffect(named soundName: String) {
        SoundManager.shared.playSound(soundName)
    }
    
    func update(currentTime: TimeInterval, layoutInfo: OBLayoutInfo) {
        // Only fire if canShoot is true
        if canShoot && currentTime - lastFireTime >= fireRate {
            fireBullet(layoutInfo: layoutInfo)
            lastFireTime = currentTime
        }
    }
    
    func fireBullet(layoutInfo: OBLayoutInfo) {
        guard let scene = scene else { return }
        
        // Bullet damage gets multiplied by damage multiplier (either 0 or 1 depending on power-up status)
        let bulletDamage: Int = 10 * damageMultiplier
        
        // Define the base size for the bullet
        let baseBulletSize = CGSize(width: 6, height: 10)
        
        // Create a new bullet with the damage and scaled size
        let bullet = OBBullet(
            damage: bulletDamage,
            texture: SKTexture(imageNamed: "playerBullet"),
            size: baseBulletSize,
            scaleFactor: layoutInfo.screenScaleFactor // Pass the scale factor
        )
        
        // Set the bullet position
        bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.size.height / 2)
        bullet.name = "testBullet"
        
        // Add the bullet to the scene
        scene.addChild(bullet)
        
        // Move the bullet upwards and remove it when out of bounds
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
        let maxY = scene.size.height - ship.size.height/2
        ship.position.x = min(maxX, max(minX, newX))
        ship.position.y = min(maxY, max(minY, newY))
    }
    
    // adding shield function, creates a blue box, not sure how it looks yet I haven't run this part
    func addShield() {
        hasShield = true
        if shieldNode == nil {
            // Use the screenScaleFactor to adjust the shield size
            let shieldRadius = 50 * layoutInfo.screenScaleFactor // Scale the shield radius by screenScaleFactor
            shieldNode = SKShapeNode(circleOfRadius: shieldRadius)
            
            shieldNode?.strokeColor = .clear
            shieldNode?.fillColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.3)
            shieldNode?.position = CGPoint(x: 0, y: 0)
            ship.addChild(shieldNode!)
            
            // Cancel existing timer if any
            shieldTimer?.invalidate()
            
            // Set new timer
            shieldTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                self?.removeShield()
            }
        }
    }
    
    func removeShield() {
        hasShield = false
        shieldNode?.removeFromParent()
        shieldNode = nil
        shieldTimer?.invalidate()
        shieldTimer = nil
        playSoundEffect(named: "shieldDamaged.mp3")
    }
    
    func setDoubleDamage() {
        damageMultiplier = 2
        
        // Cancel existing timer if any
        damageTimer?.invalidate()
        
        // Set new timer
        damageTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.removeDamageBoost()
        }
    }
    
    func removeDamageBoost() {
        damageMultiplier = 1
        damageTimer?.invalidate()
        damageTimer = nil
    }
    
    func cleanup() {
        removeShield()
        removeDamageBoost()
        ship.removeFromParent()
        playSoundEffect(named: "playerDeath.mp3")
        
    }
}
