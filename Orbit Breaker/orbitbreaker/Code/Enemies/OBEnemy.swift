//
//  OBEnemy.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//

import SpriteKit
import SwiftUI

class OBEnemy: SKSpriteNode {
    var health: Int
    var initialHealth: Int
    private var nextShootTime: TimeInterval = 0
    var canShoot: Bool
    var holdsPowerUp: Bool
    var holdsDebuff: Bool
    
    var layoutInfo: OBLayoutInfo!

    init(type: OBEnemyType, layoutInfo: OBLayoutInfo) {
        self.initialHealth = type.initialHealth
        self.health = type.initialHealth
        self.canShoot = false
        self.holdsPowerUp = false
        self.holdsDebuff = false
        self.layoutInfo = layoutInfo
        
        let scaledSize = type.size(using: layoutInfo)

        super.init(texture: SKTexture(imageNamed: "OBenemy"), color: .white, size: scaledSize)
       
        self.zPosition = 1
        self.zRotation = 0
        self.colorBlendFactor = 1.0
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: scaledSize.width / 2)
        self.physicsBody?.categoryBitMask = 0x1 << 2        // Category 2 (Enemy)
        self.physicsBody?.contactTestBitMask = 0x1 << 1     // Player bullets (Category 1)
        self.physicsBody?.collisionBitMask = 0              // No physical collisions
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.isDynamic = true
        self.physicsBody?.allowsRotation = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playSoundEffect(named soundName: String) {
        SoundManager.shared.playSound(soundName)
    }
    
    func updateSprite(forHealth health: Int, bossType: OBBossType) {
        let spriteName = OBEnemyType.spriteForHealth(health, bossType: bossType)
        self.texture = SKTexture(imageNamed: spriteName)
        
        // Flash effect
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.1)
        ])
        self.run(flash)
    }
    
    func updateShooting(currentTime: TimeInterval, scene: SKScene, waveNumber: Int) {
        guard canShoot else { return }
        
        if currentTime >= nextShootTime {
            print("Enemy shooting at time: \(currentTime)")
            shoot(scene: scene, layoutInfo: layoutInfo)
            playSoundEffect(named: "OBnew_enemy_shoot.mp3")
            
            let baseInterval = 3.0
            let randomVariation = Double.random(in: -0.5...0.5)
            nextShootTime = currentTime + baseInterval + randomVariation
        }
    }

    
    func startKamikazeBehavior() {
        guard let scene = scene else { return }
        
        self.name = "OBkamikazeEnemy"
        
        // Get the boss-themed color with increased saturation
        let glowColor: SKColor = {
            if let gameScene = scene as? OBGameScene,
               let enemyManager = gameScene.enemyManager {
                switch enemyManager.getBossType() {
                case .anger: return .red
                case .sadness: return SKColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)
                case .disgust: return SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
                case .love: return SKColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                }
            }
            return .white
        }()
        
        // Create a single optimized glow effect
        let glowNode = SKEffectNode()
        glowNode.name = "OBkamikazeGlow"
        glowNode.shouldRasterize = true
        glowNode.shouldEnableEffects = true
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10.0])
        
        let glowSprite = SKSpriteNode(texture: self.texture)
        glowSprite.color = glowColor
        glowSprite.colorBlendFactor = 1.0
        glowSprite.alpha = 0.8
        glowSprite.size = CGSize(width: self.size.width * 1.4, height: self.size.height * 1.4)
        glowNode.addChild(glowSprite)
        
        // Add glow effect after a short delay to prevent frame drops
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.addChild(glowNode)
        }
        
        // Create dramatic pulse effects
        let mainPulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 0.3),
            SKAction.fadeAlpha(to: 0.5, duration: 0.3)
        ])
        
        self.run(SKAction.repeatForever(mainPulse))
        glowNode.run(SKAction.repeatForever(glowPulse))
        
        // Start tracking with optimized updates
        let updateInterval = 1.0 / 60.0
        let trackingAction = SKAction.run { [weak self] in
            guard let self = self,
                  let player = scene.childNode(withName: "testPlayer") else { return }
            
            let dx = player.position.x - self.position.x
            let dy = player.position.y - self.position.y
            let distance = hypot(dx, dy)
            
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            
            let speed: CGFloat = 350.0
            self.position.x += normalizedDx * speed * CGFloat(updateInterval)
            self.position.y += normalizedDy * speed * CGFloat(updateInterval)
            
            let angle = atan2(dy, dx)
            self.zRotation = angle + .pi / 2
        }
        
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.repeatForever(
                SKAction.sequence([
                    trackingAction,
                    SKAction.wait(forDuration: updateInterval)
                ])
            )
        ])
        playSoundEffect(named: "OBufo_descent.mp3")

        self.run(sequence)
    }
    
    func addDynamicMovement() {
        // Side-to-side oscillation
        let oscillate = SKAction.sequence([
            SKAction.moveBy(x: 40, y: 0, duration: 1.0),
            SKAction.moveBy(x: -40, y: 0, duration: 1.0)
        ])
        run(SKAction.repeatForever(oscillate))
        
        // Random diving attacks
        if Int.random(in: 1...100) <= 15 { // 15% chance
            let originalPosition = position
            let diveSequence = SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 1...3)),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let dive = SKAction.sequence([
                        SKAction.move(to: CGPoint(x: position.x, y: position.y - 200), duration: 0.8),
                        SKAction.move(to: originalPosition, duration: 0.8)
                    ])
                    self.run(dive)
                }
            ])
            run(SKAction.repeatForever(diveSequence))
        }
    }
    
    enum OBMovementPattern {
        case oscillate
        case circle
        case figure8
        case dive
    }
    
    func addDynamicMovement(_ pattern: OBMovementPattern) {
        switch pattern {
        case .oscillate:
            applyOscillation()
        case .circle:
            applyCircularMotion()
        case .figure8:
            applyFigure8Motion()
        case .dive:
            applyDivePattern()
        }
    }
    func updateTexture(forBossType bossType: OBBossType) {
        let textureName: String
        switch bossType {
        case .anger:
            textureName = "OBangryEnemy"
        case .sadness:
            textureName = "OBsadnessEnemy"
        case .disgust:
            textureName = "OBdisgustEnemy"
        case .love:
            textureName = "OBloveEnemy"
        }
        self.texture = SKTexture(imageNamed: textureName)
    }
    
    private func applyOscillation() {
        let amplitude: CGFloat = 40
        let duration: TimeInterval = 2.0
        
        let oscillate = SKAction.sequence([
            SKAction.moveBy(x: amplitude, y: 0, duration: duration/2),
            SKAction.moveBy(x: -amplitude * 2, y: 0, duration: duration),
            SKAction.moveBy(x: amplitude, y: 0, duration: duration/2)
        ])
        
        run(SKAction.repeatForever(oscillate))
    }
    
    private func applyCircularMotion() {
        let radius: CGFloat = 30
        let duration: TimeInterval = 4.0
        let center = position
        
        let circlePath = UIBezierPath(arcCenter: .zero,
                                      radius: radius,
                                      startAngle: 0,
                                      endAngle: .pi * 2,
                                      clockwise: true)
        
        let followPath = SKAction.follow(circlePath.cgPath, asOffset: true,
                                         orientToPath: true, duration: duration)
        
        run(SKAction.repeatForever(followPath))
    }
    
    private func applyFigure8Motion() {
        let width: CGFloat = 60
        let height: CGFloat = 30
        let duration: TimeInterval = 6.0
        
        let path = UIBezierPath()
        path.move(to: .zero)
        
        // Create figure-8 shape
        let steps = 100
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let angle = t * .pi * 2
            
            let x = width * sin(angle)
            let y = height * sin(angle * 2)
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        let followPath = SKAction.follow(path.cgPath, asOffset: true,
                                         orientToPath: true, duration: duration)
        
        run(SKAction.repeatForever(followPath))
    }
    
    private func applyDivePattern() {
        let originalPosition = position
        let diveDistance: CGFloat = 200
        
        let diveSequence = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 2...5)),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                
                let dive = SKAction.sequence([
                    SKAction.group([
                        SKAction.move(to: CGPoint(x: position.x,
                                                  y: position.y - diveDistance),
                                      duration: 1.0),
                        SKAction.rotate(byAngle: .pi, duration: 1.0)
                    ]),
                    SKAction.group([
                        SKAction.move(to: originalPosition, duration: 1.0),
                        SKAction.rotate(byAngle: .pi, duration: 1.0)
                    ])
                ])
                
                self.run(dive)
            }
        ])
        
        run(SKAction.repeatForever(diveSequence))
    }
    
    private func shoot(scene: SKScene, layoutInfo: OBLayoutInfo) {
        let bullet = SKSpriteNode(texture: SKTexture(imageNamed: "OBenemyBullet"))
        bullet.size = CGSize(width: 6 * layoutInfo.screenScaleFactor, height: 10 * layoutInfo.screenScaleFactor)
        bullet.position = CGPoint(x: position.x, y: position.y - size.height/2)
        bullet.name = "OBenemyBullet"
        
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
            let powerUpType = OBPowerUps.allCases.randomElement()!
            let powerUp = OBPowerUp(type: powerUpType, color: .green, layoutInfo: layoutInfo)
            
            powerUp.name = "OBpowerUp"
            powerUp.position = CGPoint(x: position.x, y: position.y - size.height/2)
            
            powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.size)
            powerUp.physicsBody?.categoryBitMask = 0x1 << 3
            powerUp.physicsBody?.contactTestBitMask = 0x1 << 0
            powerUp.physicsBody?.collisionBitMask = 0
            powerUp.physicsBody?.affectedByGravity = false
            
            scene.addChild(powerUp)
            
            // Ensure powerUps travel full screen height
            let moveAction = SKAction.moveBy(x: 0, y: -(scene.size.height + powerUp.size.height), duration: 5)
            let removeAction = SKAction.removeFromParent()
            powerUp.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    
    func createDamageEffect() {
        // Create multiple glass-like shards
        let shardCount = 8
        let duration: TimeInterval = 0.4
        
        for _ in 0..<shardCount {
            // Create a shard
            let shard = SKShapeNode(rectOf: CGSize(width: 2, height: 2))
            shard.fillColor = .white
            shard.strokeColor = .white
            shard.alpha = 0.8
            shard.position = self.position
            shard.zPosition = self.zPosition + 1
            scene?.addChild(shard)
            
            // Random angle and distance for shard movement
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let distance = CGFloat.random(in: 15...25)
            
            // Calculate end position
            let endPoint = CGPoint(
                x: shard.position.x + cos(angle) * distance,
                y: shard.position.y + sin(angle) * distance
            )
            
            // Create move and fade actions
            let move = SKAction.move(to: endPoint, duration: duration)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: duration * 0.8)
            let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: duration)
            
            // Run actions
            shard.run(SKAction.sequence([
                SKAction.group([move, fade, rotate]),
                SKAction.removeFromParent()
            ]))
        }
    }
        
    func takeDamage(_ amount: Int) -> Bool {
            health -= amount
            
            let isDead = (health <= 0)
            if isDead { return true }
            
            createDamageEffect()
            
            if let gameScene = scene as? OBGameScene,
               let enemyManager = gameScene.enemyManager {
                updateSprite(forHealth: health, bossType: enemyManager.getBossType())
                
                // Update kamikaze effects if needed
                if name == "OBkamikazeEnemy" {
                    let glowColor: SKColor = {
                        switch enemyManager.getBossType() {
                        case .anger: return .red
                        case .sadness: return SKColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)
                        case .disgust: return SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
                        case .love: return SKColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                        }
                    }()
                    
                    // Update all glow effects
                    if let outerGlow = childNode(withName: "OBkamikazeOuterGlow") as? SKEffectNode,
                       let outerSprite = outerGlow.children.first as? SKSpriteNode {
                        outerSprite.color = glowColor
                    }
                    
                    if let innerGlow = childNode(withName: "OBkamikazeInnerGlow") as? SKEffectNode,
                       let innerSprite = innerGlow.children.first as? SKSpriteNode {
                        innerSprite.color = glowColor
                    }
                    
                    if let warning = childNode(withName: "OBkamikazeWarning") as? SKSpriteNode {
                        warning.color = glowColor
                    }
                }
            }
            
            return false
        }
    }


