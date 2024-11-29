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
    case sadness  // Round 10
    case disgust  // Round 15
    case fear     // Round 20 (future)
    
    var size: CGSize {
        switch self {
        case .anger:
            return CGSize(width: 60, height: 60)
        case .sadness:
            return CGSize(width: 80, height: 50)
        case .disgust:
            return CGSize(width: 60, height: 60)
        case .fear:
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
            return 500
        case .sadness:
            return 750
        case .disgust, .fear:
            return 750
        }
    }
}
class Boss: Enemy {
    let bossType: BossType
    private var lastShootTime: TimeInterval = 0
    private var lastSwoopTime: TimeInterval = 0
    private var lastRainCloudTime: TimeInterval = 0
    private var normalHeight: CGFloat = 0
    private var isSwooping = false
    private var moveDirection: CGFloat = 1
    private var hasEnteredScene = false
    private var entryStartTime: TimeInterval = 0
    private var raindrops: [SKNode] = []
    private var miniClouds: [SKNode] = []
    private var verticalOffset: CGFloat = 0
    private var healthBar: SKShapeNode!
    private var healthBarFill: SKShapeNode!
    private var lastPoisonBurstTime: TimeInterval = 0
    private var lastCorruptionZoneTime: TimeInterval = 0
    private var toxicPools: [SKNode] = []
    private var healthThresholds: Set<Int> = [75, 50, 25]
    private var slimeTrail: [SKShapeNode] = []
    private var lastSlimeTime: TimeInterval = 0
    private var originalPosition: CGPoint = .zero
    private var targetPosition: CGPoint = .zero
    private var velocityX: CGFloat = 0
    private var velocityY: CGFloat = 0
    private var lastDirectionChange: TimeInterval = 0
    
  
    
    
    init(type: BossType) {
        self.bossType = type
        super.init(type: .a)
        
        self.removeAllChildren()
        self.zPosition = 2
        texture = nil
        color = .clear
        alpha = 0
        
        let spriteSize = CGSize(
            width: type.size.width * 2,
            height: type.size.height * 1.7
        )
        
        let sprite = SKSpriteNode(imageNamed: type == .sadness ? "sadness" :
                                              type == .disgust ? "disgust" : "anger")
        sprite.size = spriteSize
        addChild(sprite)
        
        self.physicsBody = SKPhysicsBody(rectangleOf: spriteSize)
        self.physicsBody?.categoryBitMask = 0
        self.physicsBody?.contactTestBitMask = 0x1 << 0
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.isDynamic = true
        
        self.health = type.health
        self.initialHealth = type.health
        self.canShoot = false
        
    }
    func setupHealthBar(in scene: SKScene) {
        let barWidth: CGFloat = 200
        let barHeight: CGFloat = 20
        let yPosition = scene.size.height - 100
        
        let titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel.text = bossType == .anger ? "Anger" : bossType == .sadness ? "Sadness" : bossType == .disgust ? "Disgust" : "Anger"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: scene.size.width/2, y: yPosition + 20)
        titleLabel.name = "bossTitle"
        scene.addChild(titleLabel)
        
        healthBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
        healthBar.fillColor = .clear
        healthBar.strokeColor = .white
        healthBar.position = CGPoint(x: scene.size.width/2, y: yPosition)
        
        healthBarFill = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
        healthBarFill.fillColor = bossType == .anger ? .red : bossType == .sadness ? .blue : .green
        healthBarFill.strokeColor = .clear
        healthBarFill.position = CGPoint(x: scene.size.width/2, y: yPosition)
        
        scene.addChild(healthBar)
        scene.addChild(healthBarFill)
    }
    
    
    private func startEntryAnimation(in scene: SKScene) {
        setupHealthBar(in: scene)
        position = CGPoint(x: scene.size.width/2, y: scene.size.height + 100)
        
        physicsBody?.categoryBitMask = 0
        alpha = 0
        
        let moveDown = SKAction.moveTo(y: scene.size.height * 0.8, duration: 2.0)
        moveDown.timingMode = .easeOut
        
        let sequence = SKAction.sequence([
            SKAction.group([moveDown, SKAction.fadeIn(withDuration: 2.0)]),
            SKAction.run { [weak self] in
                self?.physicsBody?.categoryBitMask = 0x1 << 2
            }
        ])
        
        run(sequence)
    }
    private func updateHealthBar() {
        let percentage = CGFloat(health) / CGFloat(initialHealth)
        let barWidth: CGFloat = 200
        healthBarFill.path = CGPath(rect: CGRect(x: -barWidth/2, y: -10, width: barWidth * percentage, height: 20), transform: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cleanup() {
        for raindrop in raindrops {
            raindrop.removeFromParent()
        }
        raindrops.removeAll()
        
        for slime in slimeTrail {
            slime.removeFromParent()
        }
        slimeTrail.removeAll()
        
        for cloud in miniClouds {
            cloud.removeFromParent()
        }
        miniClouds.removeAll()
        
        healthBar?.removeFromParent()
        healthBarFill?.removeFromParent()
        scene?.enumerateChildNodes(withName: "bossTitle") { node, _ in
            node.removeFromParent()
        }
        scene?.enumerateChildNodes(withName: "enemyBullet") { node, _ in
            node.removeFromParent()
        }
    }
    
    private func createRaindrop(at position: CGPoint, in scene: SKScene) {
        let raindrop = SKSpriteNode(imageNamed: "raindrop")
        raindrop.size = CGSize(width: 8, height: 16)
        raindrop.position = position
        raindrop.name = "enemyBullet"
        raindrop.alpha = 0.7
        raindrop.zPosition = 1
        
        raindrop.physicsBody = SKPhysicsBody(rectangleOf: raindrop.size)
        raindrop.physicsBody?.categoryBitMask = 0x1 << 3
        raindrop.physicsBody?.contactTestBitMask = 0x1 << 0
        raindrop.physicsBody?.collisionBitMask = 0
        raindrop.physicsBody?.affectedByGravity = false
        
        scene.addChild(raindrop)
        raindrops.append(raindrop)
        
        let initialSpeed: CGFloat = 50
        let terminalSpeed: CGFloat = 300
        let accelerationTime: TimeInterval = 1.0
        let moveDistance = scene.size.height + 50
        
        let accelerate = SKAction.customAction(withDuration: accelerationTime) { node, elapsedTime in
            let progress = elapsedTime / CGFloat(accelerationTime)
            let currentSpeed = initialSpeed + (terminalSpeed - initialSpeed) * progress
            node.position.y -= currentSpeed * 1/60.0
        }
        
        let remainingDistance = moveDistance - (terminalSpeed * CGFloat(accelerationTime) / 2)
        let terminalTime = remainingDistance / terminalSpeed
        let terminalFall = SKAction.moveBy(x: 0, y: -remainingDistance, duration: terminalTime)
        
        raindrop.run(SKAction.sequence([accelerate, terminalFall, SKAction.removeFromParent()]))
    }
    
    private func createMiniCloud(at playerPosition: CGPoint, in scene: SKScene) {
        let cloud = SKSpriteNode(imageNamed: "raincloud")
        cloud.size = CGSize(width: 100, height: 60)
        cloud.position = CGPoint(x: playerPosition.x, y: playerPosition.y + 250)
        
        cloud.zPosition = 2
        
        scene.addChild(cloud)
        miniClouds.append(cloud)
        
        let warningSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.3),
            SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        ])
        cloud.run(SKAction.repeat(warningSequence, count: 3))
        
        let startDelay = SKAction.wait(forDuration: 1.5)
        var dropCount = 0
        let maxDrops = 10
        
        let dropSequence = SKAction.sequence([
            SKAction.run { [weak self] in
                if dropCount < maxDrops {
                    self?.createRaindrop(at: CGPoint(x: cloud.position.x + CGFloat.random(in: -20...20),
                                                     y: cloud.position.y - 15),
                                         in: scene)
                    dropCount += 1
                }
            },
            SKAction.wait(forDuration: 0.7)
        ])
        
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 7.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        
        cloud.run(SKAction.sequence([
            startDelay,
            SKAction.group([
                SKAction.repeat(dropSequence, count: maxDrops),
                fadeOut
            ])
        ]))
    }
    
    func update(currentTime: TimeInterval, in scene: SKScene) {
        if !hasEnteredScene {
            startEntryAnimation(in: scene)
            entryStartTime = currentTime
            hasEnteredScene = true
            return
        }
        
        let timeSinceEntry = currentTime - entryStartTime
        
        if normalHeight == 0 {
            normalHeight = scene.size.height * 0.8
        }
        
        if timeSinceEntry > 3.0 {
            self.canShoot = true
            
            if !isSwooping {
                if bossType == .sadness {
                    handleSadnessMovement(currentTime: currentTime, in: scene)
                } else if bossType == .anger {
                    handleAngerMovement(currentTime: currentTime, in: scene)
                    if currentTime - lastShootTime >= 3.0 {
                        shootFireballPattern(in: scene)
                        lastShootTime = currentTime
                    }
                } else if bossType == .disgust {
                    handleDisgustMovement(currentTime: currentTime, in: scene)
                }
            }
        }
        
        if bossType == .anger {
            if lastSwoopTime == 0 {
                lastSwoopTime = currentTime - 5.0
            }
            
            if currentTime - lastSwoopTime >= 7.0 && !isSwooping {
                startSwoop(in: scene)
                lastSwoopTime = currentTime
            }
        }
    }
    
    private func handleDisgustMovement(currentTime: TimeInterval, in scene: SKScene) {
        guard let player = scene.childNode(withName: "testPlayer") else { return }
        
        let maxSpeed: CGFloat = 200
        let acceleration: CGFloat = 2.5
        
        let dx = player.position.x - position.x
        let dy = player.position.y - position.y
        let distance = hypot(dx, dy)
        
        if distance > 0 {
            let directionX = dx / distance
            let directionY = dy / distance
            
            velocityX += directionX * acceleration
            velocityY += directionY * acceleration
            
            let currentSpeed = hypot(velocityX, velocityY)
            if currentSpeed > maxSpeed {
                let scale = maxSpeed / currentSpeed
                velocityX *= scale
                velocityY *= scale
            }
        }
        
        velocityX *= 0.97
        velocityY *= 0.97
        
        position.x += velocityX * 1/60
        position.y += velocityY * 1/60
        
        if currentTime - lastSlimeTime >= 0.05 {  // More frequent trail
            createSlimeTrail(in: scene)
            lastSlimeTime = currentTime
        }
        
        if currentTime - lastShootTime >= 0.8 {
            shootToxicProjectile(in: scene)
            lastShootTime = currentTime
        }
    }

    
    private func updateTargetPosition(in scene: SKScene) {
        let padding: CGFloat = 80
        targetPosition = CGPoint(
            x: CGFloat.random(in: padding...(scene.size.width - padding)),
            y: CGFloat.random(in: padding...(scene.size.height - 150))
        )
    }
       
    private func createSlimeTrail(in scene: SKScene) {
        let slime = SKShapeNode(circleOfRadius: 25)  // Bigger radius
        slime.fillColor = .green
        slime.strokeColor = .init(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.4)
        slime.alpha = 0.6  // More visible
        slime.position = position
        slime.zPosition = 1
        
        scene.addChild(slime)
        slimeTrail.append(slime)
        
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
        let scaleDown = SKAction.scale(to: 0.7, duration: 2.0)  // Longer duration
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)  // Longer duration
        
        slime.run(SKAction.sequence([
            scaleUp,
            SKAction.group([scaleDown, fadeOut]),
            SKAction.removeFromParent()
        ])) { [weak self] in
            self?.slimeTrail.removeFirst()
        }
        
        slime.physicsBody = SKPhysicsBody(circleOfRadius: 25)
        slime.physicsBody?.categoryBitMask = 0x1 << 3
        slime.physicsBody?.contactTestBitMask = 0x1 << 0
        slime.physicsBody?.collisionBitMask = 0
        slime.physicsBody?.isDynamic = false
    }
    
    private func shootToxicProjectile(in scene: SKScene) {
        guard let player = scene.childNode(withName: "testPlayer") else { return }
        
        let projectile = SKSpriteNode(imageNamed: "slimeBall")
        projectile.size = CGSize(width: 20, height: 20)
        projectile.position = position
        projectile.name = "enemyBullet"
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        projectile.physicsBody?.categoryBitMask = 0x1 << 3
        projectile.physicsBody?.contactTestBitMask = 0x1 << 0
        projectile.physicsBody?.collisionBitMask = 0
        projectile.physicsBody?.affectedByGravity = false
        
        scene.addChild(projectile)
        
        let direction = CGPoint(
            x: player.position.x - position.x,
            y: player.position.y - position.y
        )
        let distance = hypot(direction.x, direction.y)
        let normalizedDirection = CGPoint(
            x: direction.x / distance,
            y: direction.y / distance
        )
        
        let speed: CGFloat = 400
        let screenDiagonal = hypot(scene.size.width, scene.size.height)
        let moveVector = CGVector(
            dx: normalizedDirection.x * screenDiagonal,
            dy: normalizedDirection.y * screenDiagonal
        )
        
        projectile.run(SKAction.sequence([
            SKAction.move(by: moveVector, duration: TimeInterval(screenDiagonal / speed)),
            SKAction.removeFromParent()
        ]))
    }

    

    
    private func handleSadnessMovement(currentTime: TimeInterval, in scene: SKScene) {
        let time = currentTime * 0.5
        let radius: CGFloat = 100
        let centerX = scene.size.width / 2
        let centerY = scene.size.height * 0.7
        
        if currentTime - entryStartTime > 3.5 {
            let targetX = centerX + radius * sin(time)
            let targetY = centerY + radius * 0.5 * sin(2 * time)
            
            let smoothing: CGFloat = 0.05
            position = CGPoint(
                x: position.x + (targetX - position.x) * smoothing,
                y: position.y + (targetY - position.y) * smoothing
            )
        }
        
        if currentTime - lastRainCloudTime >= 12.0 {
            if let player = scene.childNode(withName: "testPlayer") {
                createMiniCloud(at: player.position, in: scene)
                lastRainCloudTime = currentTime
            }
        }
        
        if currentTime - lastShootTime >= 0.8 {
            createRaindrop(at: CGPoint(x: position.x + CGFloat.random(in: -20...20), y: position.y - 20), in: scene)
            lastShootTime = currentTime
        }
    }
    
    private func handleAngerMovement(currentTime: TimeInterval, in scene: SKScene) {
        let moveSpeed: CGFloat = 2.0
        let targetX = position.x + moveSpeed * moveDirection
        position.x = targetX
        
        if position.x >= scene.size.width - 80 {
            moveDirection = -1
        } else if position.x <= 80 {
            moveDirection = 1
        }
        
        let maxHeight = scene.size.height - 150  // Increased distance from health bar
        let minHeight = maxHeight - 30
        verticalOffset = sin(currentTime * 2) * 15
        position.y = min(maxHeight, max(minHeight, normalHeight + verticalOffset))
    }
    
    
    
    override func takeDamage(_ amount: Int) -> Bool {
        health -= amount
        updateHealthBar()
        
        if bossType == .disgust {
            let percentage = Float(health) / Float(initialHealth) * 100
            for threshold in healthThresholds where percentage <= Float(threshold) {
                createPoisonBurst(in: scene!)
                healthThresholds.remove(threshold)
            }
        }
        
        if health <= 0 {
            cleanup()
            return true
        }
        
        return false
    }
    
    private func createPoisonBurst(in scene: SKScene) {
        let bulletCount = 12
        let bulletSpeed: CGFloat = 300
        
        for i in 0..<bulletCount {
            let angle = (CGFloat(i) / CGFloat(bulletCount)) * CGFloat.pi * 2
            
            let bullet = SKShapeNode(circleOfRadius: 8)
            bullet.fillColor = .green
            bullet.strokeColor = .init(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
            bullet.name = "enemyBullet"
            bullet.position = position
            
            bullet.physicsBody = SKPhysicsBody(circleOfRadius: 8)
            bullet.physicsBody?.categoryBitMask = 0x1 << 3
            bullet.physicsBody?.contactTestBitMask = 0x1 << 0
            bullet.physicsBody?.collisionBitMask = 0
            bullet.physicsBody?.affectedByGravity = false
            
            scene.addChild(bullet)
            
            let screenDiagonal = hypot(scene.size.width, scene.size.height)
            let dx = cos(angle) * screenDiagonal
            let dy = sin(angle) * screenDiagonal
            
            let moveVector = CGVector(dx: dx, dy: dy)
            let duration = screenDiagonal / bulletSpeed
            
            bullet.run(SKAction.sequence([
                SKAction.move(by: moveVector, duration: duration),
                SKAction.removeFromParent()
            ]))
        }
    }

    
    private func startSwoop(in scene: SKScene) {
        isSwooping = true
        let moveDown = SKAction.moveTo(y: scene.size.height * 0.2, duration: 0.5)
        let wait = SKAction.wait(forDuration: 0.3)
        let moveUp = SKAction.moveTo(y: normalHeight, duration: 0.5)
        let sequence = SKAction.sequence([moveDown, wait, moveUp, SKAction.run { [weak self] in
            self?.isSwooping = false
        }])
        run(sequence)
    }
    
    private func updateMovement(currentTime: TimeInterval, in scene: SKScene) {
        let moveSpeed: CGFloat = 2.0
        position.x += moveSpeed * moveDirection
        if position.x >= scene.size.width - 80 {
            moveDirection = -1
        } else if position.x <= 80 {
            moveDirection = 1
        }
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
