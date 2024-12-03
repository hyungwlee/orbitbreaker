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
    
    func startKamikazeBehavior() {
        guard let scene = scene else { return }
        
        // Mark this enemy as a kamikaze
        self.name = "kamikazeEnemy"
        
        // Change appearance to indicate danger
        self.run(SKAction.colorize(with: .red, colorBlendFactor: 0.7, duration: 0.3))
        
        // Add pulsing warning effect
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        self.run(SKAction.repeatForever(pulse))
        
        // Start tracking and attacking player
        let updateInterval = 1.0 / 60.0 // 60fps
        let trackingAction = SKAction.run { [weak self] in
            guard let self = self,
                  let player = scene.childNode(withName: "testPlayer") else { return }
            
            // Calculate direction to player
            let dx = player.position.x - self.position.x
            let dy = player.position.y - self.position.y
            let distance = hypot(dx, dy)
            
            // Normalize direction
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            
            // Move towards player
            let speed: CGFloat = 300.0
            self.position.x += normalizedDx * speed * CGFloat(updateInterval)
            self.position.y += normalizedDy * speed * CGFloat(updateInterval)
            
            // Rotate to face player
            let angle = atan2(dy, dx)
            self.zRotation = angle + .pi / 2
        }
        
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: 1.0), // Wait before charging
            SKAction.repeatForever(
                SKAction.sequence([
                    trackingAction,
                    SKAction.wait(forDuration: updateInterval)
                ])
            )
        ])
        
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
    
    enum MovementPattern {
           case oscillate
           case circle
           case figure8
           case dive
       }
       
       func addDynamicMovement(_ pattern: MovementPattern) {
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
    func updateTexture(forBossType bossType: BossType) {
        let textureName: String
        switch bossType {
        case .anger:
            textureName = "angryEnemy"
        case .sadness:
            textureName = "sadnessEnemy"
        case .disgust:
            textureName = "disgustEnemy"
        case .love:
            textureName = "loveEnemy"
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
    
    private func shoot(scene: SKScene) {
        let bullet = SKSpriteNode(texture: SKTexture(imageNamed: "enemyBullet"))
        bullet.size = CGSize(width: 8, height: 12)
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

