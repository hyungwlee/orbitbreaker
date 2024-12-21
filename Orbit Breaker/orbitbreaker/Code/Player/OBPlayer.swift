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
    public var fireRate: TimeInterval = 0.15
    private var isDragging = false
    private var shieldNode: SKShapeNode?
    var hasShield: Bool = false
    public var damageMultiplier: Int = 1
    private var shieldTimer: Timer?
    private var damageTimer: Timer?
    var canShoot: Bool = true
    var scaleFactor: CGFloat
    var layoutInfo: OBLayoutInfo
    private var currentShieldStartTime: TimeInterval?
    private var currentDoubleDamageStartTime: TimeInterval?
    
    private let SHIELD_DURATION: TimeInterval = 10.0
    private let DOUBLE_DAMAGE_DURATION: TimeInterval = 8.0

    init(scene: SKScene, layoutInfo: OBLayoutInfo) {
        self.scene = scene
        self.scaleFactor = 1.5
        self.layoutInfo = layoutInfo

        ship = SKSpriteNode(imageNamed: "OBPlayer")
        ship.size = CGSize(width: layoutInfo.nodeSize.width * scaleFactor,
                           height: layoutInfo.nodeSize.height * scaleFactor)
        
        let scalePosition: CGFloat = 0.3
        ship.position = CGPoint(x: layoutInfo.nodePosition.x, y: layoutInfo.nodePosition.y * scalePosition)
        
        ship.name = "testPlayer"
        
        ship.physicsBody = SKPhysicsBody(texture: ship.texture!, size: ship.size)
        ship.physicsBody?.categoryBitMask = 0x1 << 0
        ship.physicsBody?.contactTestBitMask = 0x1 << 2 | 0x1 << 3 | 0x1 << 4
        ship.physicsBody?.collisionBitMask = 0
        ship.physicsBody?.affectedByGravity = false
        scene.addChild(ship)
    }
    
    func playSoundEffect(named soundName: String) {
        OBSoundManager.shared.playSound(soundName)
    }
    
    func update(currentTime: TimeInterval, layoutInfo: OBLayoutInfo) {
        self.layoutInfo = layoutInfo
        
        // Bullet firing logic
        if canShoot && currentTime - lastFireTime >= fireRate {
            fireBullet(layoutInfo: layoutInfo)
            lastFireTime = currentTime
        }
        
        // Check shield expiration
        if let shieldStart = currentShieldStartTime {
            if currentTime - shieldStart >= SHIELD_DURATION {
                removeShield()
            }
        }
        
        // Check double damage expiration
        if let damageStart = currentDoubleDamageStartTime {
            if currentTime - damageStart >= DOUBLE_DAMAGE_DURATION {
                removeDamageBoost()
            }
        }
    }
    
    func addShield() {
        guard let scene = scene else { return }
        
        hasShield = true
        if shieldNode == nil {
            let shieldRadius = 50 * layoutInfo.screenScaleFactor
            shieldNode = SKShapeNode(circleOfRadius: shieldRadius)
            
            shieldNode?.strokeColor = .clear
            shieldNode?.fillColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.3)
            shieldNode?.position = CGPoint(x: 0, y: 0)
            ship.addChild(shieldNode!)
        }

        // Update the shield start time
        currentShieldStartTime = scene.isPaused ? 0 : CACurrentMediaTime()
        
        // Cancel existing timer if any
        shieldTimer?.invalidate()
        shieldTimer = nil
    }
    
    func setDoubleDamage() {
        guard let scene = scene else { return }
        
        damageMultiplier = 2
        
        // Update the double damage start time
        currentDoubleDamageStartTime = scene.isPaused ? 0 : CACurrentMediaTime()
        
        // Cancel existing timer if any
        damageTimer?.invalidate()
        damageTimer = nil
    }
    
    func removeShield(playSound: Bool = true) {
        hasShield = false
        shieldNode?.removeFromParent()
        shieldNode = nil
        shieldTimer?.invalidate()
        shieldTimer = nil
        currentShieldStartTime = nil
        if playSound {
            playSoundEffect(named: "OBshieldDamaged.mp3")
        }
    }
    
    func removeDamageBoost() {
        damageMultiplier = 1
        damageTimer?.invalidate()
        damageTimer = nil
        currentDoubleDamageStartTime = nil
    }
    
    // Rest of the class implementation remains the same...
    func fireBullet(layoutInfo: OBLayoutInfo) {
        guard let scene = scene else { return }
        
        let bulletDamage: Int = 10 * damageMultiplier
        let baseBulletSize = CGSize(width: 6, height: 10)
        
        let bullet = OBBullet(
                    damage: bulletDamage,
                    texture: SKTexture(imageNamed: "OBplayerBullet"),
                    size: baseBulletSize,
                    scaleFactor: layoutInfo.screenScaleFactor,
                    isDoubleDamage: damageMultiplier > 1
        )
        
        bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.size.height / 2)
        bullet.name = "OBtestBullet"
        
        scene.addChild(bullet)
        
        let moveAction = SKAction.moveBy(x: 0, y: scene.size.height + bullet.size.height, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func handleTouch(_ touch: UITouch) {
        guard let scene = scene else { return }
        let location = touch.location(in: scene)
        
        let previousLocation = touch.previousLocation(in: scene)
        let deltaX = location.x - previousLocation.x
        let deltaY = location.y - previousLocation.y
        let newX = ship.position.x + deltaX
        let newY = ship.position.y + deltaY
        
        let minX = ship.size.width/2
        let maxX = scene.size.width - ship.size.width/2
        let minY = ship.size.height/2
        let maxY = scene.size.height - ship.size.height/2
        ship.position.x = min(maxX, max(minX, newX))
        ship.position.y = min(maxY, max(minY, newY))
    }
    
    func cleanup() {
        removeShield(playSound: false)
        removeDamageBoost()
        ship.removeFromParent()
        playSoundEffect(named: "OBplayerDeath.mp3")
    }
}
