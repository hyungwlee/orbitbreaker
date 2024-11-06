//
//  Bosses.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/4/24.
//

import SpriteKit

private enum BossMovementPattern: Int, CaseIterable {
    case circular = 0
    case figureEight = 1
    case teleporting = 2
}

enum BossType {
    case anger    // Round 5
    case sadness  // Round 10 (future)
    case disgust      // Round 15 (future)
    case fear     // Round 20 (future)
    
    var size: CGSize {
        switch self {
        case .anger:
            return CGSize(width: 60, height: 60)  // Made boss bigger
        case .sadness, .disgust, .fear:
            return CGSize(width: 60, height: 60)
        }
    }
    
    var color: SKColor {
        switch self {
        case .anger:
            return .red
        case .sadness:
            return .blue
        case .disgust:
            return .green
        case .fear:
            return .purple
        }
    }
    
    var health: Int {
        switch self {
        case .anger:
            return 300
        case .sadness, .disgust, .fear:
            return 350
        }
    }
}
class Boss: Enemy {
    
    let bossType: BossType
        private var lastShootTime: TimeInterval = 0
        private var lastSwoopTime: TimeInterval = 0
        private var normalHeight: CGFloat = 0
        private var isSwooping = false
        private var moveDirection: CGFloat = 1
        private var hasEnteredScene = false
        private var entryStartTime: TimeInterval = 0
        
        init(type: BossType) {
            self.bossType = type
            super.init(type: .a)
            
            // Remove default circle shape
            self.removeAllChildren()
            
            // Create new circle shape for boss
            let circleShape = SKShapeNode(circleOfRadius: type.size.width / 2)
            circleShape.fillColor = type.color
            circleShape.strokeColor = SKColor.white
            circleShape.lineWidth = 2.0
            self.addChild(circleShape)
            
            // Update physics body for boss size
            self.physicsBody = SKPhysicsBody(circleOfRadius: type.size.width / 2)
                   self.physicsBody?.categoryBitMask = 0x1 << 2     // Category 3
                   self.physicsBody?.contactTestBitMask = 0x1 << 0  // Will contact with player (Category 1)
                   self.physicsBody?.collisionBitMask = 0
                   self.physicsBody?.affectedByGravity = false
                   self.physicsBody?.isDynamic = true
            
            self.health = type.health
            self.canShoot = false  // Start with shooting disabled
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
    private func startEntryAnimation(in scene: SKScene) {
            // Start position above screen
            position = CGPoint(x: scene.size.width/2, y: scene.size.height + 100)
            
            // Create dramatic entry animation
            let moveDown = SKAction.moveTo(y: scene.size.height * 0.8, duration: 2.0)
            moveDown.timingMode = .easeOut  // Slow down as it reaches position
            
            // Add some rotation for style
            let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 2.0)
            
            // Combine movements
            let entryGroup = SKAction.group([moveDown, rotate])
            
            run(entryGroup)
        }
    
    func update(currentTime: TimeInterval, in scene: SKScene) {
            if !hasEnteredScene {
                startEntryAnimation(in: scene)
                entryStartTime = currentTime
                hasEnteredScene = true
                return
            }
            
            // Time elapsed since entry started
            let timeSinceEntry = currentTime - entryStartTime
            
            // Initialize normal height once
            if normalHeight == 0 {
                normalHeight = scene.size.height * 0.8
            }
            
            // Only start attack patterns after entry animation and delay
            if timeSinceEntry > 3.0 {  // 3 second delay after entry
                // Enable shooting after entry
                self.canShoot = true
                
                // Only update shooting and movement if not swooping
                if !isSwooping {
                    if lastShootTime == 0 {
                        // First shot should be 2 seconds after we start attacking
                        lastShootTime = currentTime - 1.0  // Will trigger first shot in 2 seconds
                    }
                    
                    if currentTime - lastShootTime >= 3.0 {
                        shootFireballPattern(in: scene)
                        lastShootTime = currentTime
                    }
                    updateMovement(currentTime: currentTime, in: scene)
                }
                
                // Initialize swoop timer after entry
                if lastSwoopTime == 0 {
                    // First swoop should be 5 seconds after we start attacking
                    lastSwoopTime = currentTime - 5.0
                }
                
                // Check for swoop timing
                if currentTime - lastSwoopTime >= 7.0 && !isSwooping {
                    startSwoop(in: scene)
                    lastSwoopTime = currentTime
                }
            }
        }
    
    private func startSwoop(in scene: SKScene) {
        isSwooping = true
        
        // Simple down and up movement
        let moveDown = SKAction.moveTo(y: scene.size.height * 0.2, duration: 0.5)
        let wait = SKAction.wait(forDuration: 0.3)
        let moveUp = SKAction.moveTo(y: normalHeight, duration: 0.5)
        
        let sequence = SKAction.sequence([
            moveDown,
            wait,
            moveUp,
            SKAction.run { [weak self] in
                self?.isSwooping = false
            }
        ])
        
        run(sequence)
    }
    
    private func updateMovement(currentTime: TimeInterval, in scene: SKScene) {
        let moveSpeed: CGFloat = 2.0 // Slower movement
        
        // Side-to-side movement
        position.x += moveSpeed * moveDirection
        
        // Change direction at screen edges
        if position.x >= scene.size.width - 80 {
            moveDirection = -1
        } else if position.x <= 80 {
            moveDirection = 1
        }
    }
    
    override func takeDamage(_ amount: Int) -> Bool {
            health -= amount
            print("Boss took \(amount) damage. Health remaining: \(health)")
            
            // Visual feedback
            if let circleShape = self.children.first as? SKShapeNode {
                circleShape.run(SKAction.sequence([
                    SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.1),
                    SKAction.colorize(with: bossType.color, colorBlendFactor: 1.0, duration: 0.1)
                ]))
            }
            
            return health <= 0
        }
        
    private func shootFireballPattern(in scene: SKScene) {
           let bulletCount = 3
           let spreadAngle = CGFloat.pi / 4
           let bulletSpeed: CGFloat = 300
           
           for i in 0..<bulletCount {
               let fireball = SKShapeNode(circleOfRadius: 8)
               fireball.fillColor = SKColor.orange
               fireball.strokeColor = SKColor.yellow
               fireball.name = "enemyBullet"
               
               // Create glow effect
               let glowEffect = SKEffectNode()
               glowEffect.shouldRasterize = true
               glowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
               
               let glowShape = SKShapeNode(circleOfRadius: 10)
               glowShape.fillColor = SKColor.yellow
               glowShape.strokeColor = SKColor.clear
               glowEffect.addChild(glowShape)
               fireball.addChild(glowEffect)
               
               fireball.position = position
               fireball.physicsBody = SKPhysicsBody(circleOfRadius: 8)
               fireball.physicsBody?.categoryBitMask = 0x1 << 3
               fireball.physicsBody?.contactTestBitMask = 0x1 << 0
               fireball.physicsBody?.collisionBitMask = 0
               fireball.physicsBody?.affectedByGravity = false
               
               scene.addChild(fireball)
               
               var angle: CGFloat = 0
               switch i {
               case 0: angle = spreadAngle/2
               case 1: angle = 0
               case 2: angle = -spreadAngle/2
               default: break
               }
               
               let dx = sin(angle) * bulletSpeed
               let dy = -bulletSpeed
               
               let moveDistance = scene.size.height + 100
               let moveDuration = moveDistance / bulletSpeed
               
               let moveVector = CGVector(dx: dx * moveDuration, dy: -moveDistance)
               let moveAction = SKAction.move(by: moveVector, duration: moveDuration)
               fireball.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
           }
       }
}
