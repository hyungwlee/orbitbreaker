//
//  TestPlayer.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

// TestPlayer.swift

import SpriteKit

class TestPlayer {
    private weak var scene: SKScene?
    private var ship: SKSpriteNode
    private var lastFireTime: TimeInterval = 0
    private var fireRate: TimeInterval = 0.2  // Made variable to allow modification
    private var isDragging = false
    private var canShoot = true  // New property to control shooting
    private var disableButton: SKNode
    private var rapidFireButton: SKNode
    
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
        
        // Create disable shooting button
        let buttonSize = CGSize(width: 60, height: 60)
        disableButton = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        (disableButton as! SKShapeNode).fillColor = .red
        (disableButton as! SKShapeNode).strokeColor = .white
        disableButton.position = CGPoint(x: scene.size.width - 40, y: 40)
        disableButton.name = "disableButton"
        
        let disableLabel = SKLabelNode(text: "Stop")
        disableLabel.fontSize = 16
        disableLabel.fontColor = .white
        disableLabel.verticalAlignmentMode = .center
        disableLabel.horizontalAlignmentMode = .center
        disableLabel.position = CGPoint(x: 0, y: 0)
        disableButton.addChild(disableLabel)
        
        // Create rapid fire button
        rapidFireButton = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        (rapidFireButton as! SKShapeNode).fillColor = .green
        (rapidFireButton as! SKShapeNode).strokeColor = .black
        rapidFireButton.position = CGPoint(x: 40, y: 40)
        rapidFireButton.name = "rapidFireButton"
        
        let rapidFireLabel = SKLabelNode(text: "Rapid")
        rapidFireLabel.fontSize = 16
        rapidFireLabel.fontColor = .white
        rapidFireLabel.verticalAlignmentMode = .center
        rapidFireLabel.horizontalAlignmentMode = .center
        rapidFireLabel.position = CGPoint(x: 0, y: 0)
        rapidFireButton.addChild(rapidFireLabel)
        
        scene.addChild(ship)
        scene.addChild(disableButton)
        scene.addChild(rapidFireButton)
    }
    
    func update(currentTime: TimeInterval) {
        if canShoot && currentTime - lastFireTime >= fireRate {
            fireBullet()
            lastFireTime = currentTime
        }
    }
    
    private func fireBullet() {
        guard let scene = scene else { return }
        
        let bullet = SKSpriteNode(color: .yellow, size: CGSize(width: 4, height: 10))
        bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.size.height/2)
        bullet.name = "testBullet"
        
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.categoryBitMask = 0x1 << 1
        bullet.physicsBody?.contactTestBitMask = 0x1 << 2
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.affectedByGravity = false
        
        scene.addChild(bullet)
        
        let moveAction = SKAction.moveBy(x: 0, y: scene.size.height + bullet.size.height, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func handleTouch(_ touch: UITouch) {
        guard let scene = scene else { return }
        let location = touch.location(in: scene)
        
        // Check if either button was tapped
        if disableButton.contains(location) {
            toggleShooting()
            return
        }
        
        if rapidFireButton.contains(location) {
            toggleRapidFire()
            return
        }
        
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
    
    private func toggleShooting() {
        canShoot.toggle()
        (disableButton as! SKShapeNode).fillColor = canShoot ? .red : .gray
        let label = disableButton.children.first as! SKLabelNode
        label.text = canShoot ? "Stop" : "Start"
    }
    
    private func toggleRapidFire() {
        if fireRate == 0.01 {
            fireRate = 0.2  // Normal fire rate
            (rapidFireButton as! SKShapeNode).fillColor = .green
        } else {
            fireRate = 0.01  // Rapid fire rate
            (rapidFireButton as! SKShapeNode).fillColor = .yellow
        }
    }
    
    func cleanup() {
        ship.removeFromParent()
        disableButton.removeFromParent()
        rapidFireButton.removeFromParent()
    }
}
