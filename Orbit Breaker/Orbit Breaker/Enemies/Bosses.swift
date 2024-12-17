//
//  Bosses.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/4/24.
//

import SpriteKit
import CoreHaptics

private enum BossMovementPattern: Int, CaseIterable {
    case circular = 0
    case figureEight = 1
    case teleporting = 2
}

enum BossType {
    case anger    // Round 5
    case sadness  // Round 10
    case disgust  // Round 15
    case love     // Round 20 (future)
    
    var size: CGSize {
        switch self {
        case .anger:
            return CGSize(width: 60, height: 60)
        case .sadness:
            return CGSize(width: 80, height: 50)
        case .disgust:
            return CGSize(width: 60, height: 60)
        case .love:
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
        case .love:
            return .systemPink
        }
    }
    
    var health: Int {
        switch self {
        case .disgust:
            return 750
        case .sadness:
            return 1250
        case .anger, .love:
            return 1500
            
            
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
    private(set) var hasEnteredScene = false
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
    private var lastHeartBurstTime: TimeInterval = 0
    private var heartProjectiles: [SKNode] = []
    var heartShields: [SKNode] = []
    private var shieldHealth: [SKNode: Int] = [:]
    private var shieldDamageCount: [SKNode: Int] = [:]
    private var shieldHits: [SKNode: Int] = [:]
    private var shieldRegenerationTimer: TimeInterval = 0
    private var isRegeneratingShields = false
    private var lastShieldRegenTime: TimeInterval = 0
    private let shieldRegenDelay: TimeInterval = 8.0 // Wait 8 seconds before starting regen
    private let shieldRegenInterval: TimeInterval = 0.5 // Add one shield every 0.5 seconds
    private let maxShields = 20
    private var shieldsHaveBeenCreated = false
    private var lastHealthPercentage: CGFloat = 1.0
    private var healthBarContainer: SKNode?
    private var originalFillColor: SKColor = .red  // Store the original color
    
    
    
    // In Boss.swift
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
                                    type == .disgust ? "disgust" : type == .love ? "love" : "anger")
        sprite.size = spriteSize
        addChild(sprite)
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: min(type.size.width, type.size.height))
        self.physicsBody?.categoryBitMask = 0x1 << 4
        self.physicsBody?.contactTestBitMask = 0x1 << 1
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.isDynamic = true
        
        self.health = type.health
        self.initialHealth = type.health
        self.canShoot = false
        self.name = "boss"
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.bossType = .anger  // Default value
        super.init(coder: aDecoder)
    }
    
    func setupHealthBar(in scene: SKScene) {
        // Clean up any existing health bar
        healthBarContainer?.removeFromParent()
        
        // Create a container for all health bar elements
        healthBarContainer = SKNode()
        
        let barWidth: CGFloat = 250
        let barHeight: CGFloat = 35
        
        // Adjusted padding for Dynamic Island - lower value to position it just below
        let topPadding: CGFloat = UIDevice.current.hasNotch ? 90 : 40
        let yPosition = scene.size.height - topPadding - barHeight
        
        // Rest of the setup remains the same...
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = bossType == .anger ? "ANGER" :
                         bossType == .sadness ? "SADNESS" :
                         bossType == .disgust ? "DISGUST" :
                         bossType == .love ? "LOVE" : "ANGER"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: scene.size.width/2, y: yPosition + 30)
        titleLabel.name = "bossTitle"
        
        let shadowLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadowLabel.text = titleLabel.text
        shadowLabel.fontSize = titleLabel.fontSize
        shadowLabel.fontColor = .black
        shadowLabel.position = CGPoint(x: 2, y: -2)
        shadowLabel.zPosition = -1
        titleLabel.addChild(shadowLabel)
        
        let cornerRadius: CGFloat = 10
        let containerRect = CGRect(x: -barWidth/2, y: -barHeight/2, width: barWidth, height: barHeight)
        let containerPath = CGPath(roundedRect: containerRect,
                                 cornerWidth: cornerRadius,
                                 cornerHeight: cornerRadius,
                                 transform: nil)
        
        healthBar = SKShapeNode(path: containerPath)
        healthBar.fillColor = SKColor(white: 0.1, alpha: 1.0)
        healthBar.strokeColor = .white
        healthBar.lineWidth = 3.0
        healthBar.position = CGPoint(x: scene.size.width/2, y: yPosition)
        
        originalFillColor = bossType == .anger ? SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) :
                           bossType == .sadness ? SKColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0) :
                           bossType == .disgust ? SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0) :
                           bossType == .love ? SKColor(red: 0.9, green: 0.2, blue: 0.5, alpha: 1.0) :
                           SKColor.red
        
        healthBarFill = SKShapeNode(path: containerPath)
        healthBarFill.fillColor = originalFillColor
        healthBarFill.strokeColor = .clear
        healthBarFill.position = CGPoint(x: scene.size.width/2, y: yPosition)
        healthBarFill.zPosition = 1
        
        let innerStroke = SKShapeNode(path: containerPath)
        innerStroke.fillColor = .clear
        innerStroke.strokeColor = .white
        innerStroke.lineWidth = 2.0
        innerStroke.position = CGPoint(x: scene.size.width/2, y: yPosition)
        innerStroke.zPosition = 2
        
        healthBarContainer?.addChild(titleLabel)
        healthBarContainer?.addChild(healthBar)
        healthBarContainer?.addChild(healthBarFill)
        healthBarContainer?.addChild(innerStroke)
        
        scene.addChild(healthBarContainer!)
        
        updateHealthBar()
    }

    private func updateHealthBar() {
        let percentage = CGFloat(health) / CGFloat(initialHealth)
        let barWidth: CGFloat = 250
        let barHeight: CGFloat = 35
        let cornerRadius: CGFloat = 10
        
        let currentWidth = max(0, barWidth * percentage)
        
        let currentRect = CGRect(x: -barWidth/2, y: -barHeight/2, width: currentWidth, height: barHeight)
        let newPath = CGPath(roundedRect: currentRect,
                            cornerWidth: cornerRadius,
                            cornerHeight: cornerRadius,
                            transform: nil)
        
        healthBarFill.path = newPath
        
        // Modified damage effect to be more subtle
        if percentage < lastHealthPercentage {
            // Create a subtle flash overlay instead of changing the fill color
            let flashNode = SKShapeNode(path: newPath)
            flashNode.fillColor = .white
            flashNode.strokeColor = .clear
            flashNode.alpha = 0.3  // Reduced alpha for subtlety
            healthBarFill.addChild(flashNode)
            
            // Quick fade out and remove
            let fadeOut = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.removeFromParent()
            ])
            flashNode.run(fadeOut)
            
            // Small scale pulse
            let smallPulse = SKAction.sequence([
                SKAction.scale(to: 1.02, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ])
            healthBarFill.run(smallPulse)
        }
        
        lastHealthPercentage = percentage
    }

    private func startEntryAnimation(in scene: SKScene) {
        setupHealthBar(in: scene)
        position = CGPoint(x: scene.size.width/2, y: scene.size.height + 100)
        
        // Create intense haptic pattern for boss entry
        if let engine = (scene as? GameScene)?.hapticsEngine {
            do {
                // Create a continuous haptic pattern that intensifies
                var events = [CHHapticEvent]()
                
                // Start with low intensity rumble
                for i in 0..<20 {
                    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i) / 20.0)
                    let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    let event = CHHapticEvent(eventType: .hapticContinuous,
                                            parameters: [intensity, sharpness],
                                            relativeTime: TimeInterval(i) * 0.1,
                                            duration: 0.15)
                    events.append(event)
                }
                
                // Create and start the pattern
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("Failed to play haptic pattern: \(error.localizedDescription)")
            }
        }
        
        // Rest of the existing animation code...
        physicsBody?.categoryBitMask = 0
        physicsBody?.contactTestBitMask = 0
        alpha = 0
        
        let finalHeight = scene.size.height * (bossType == .anger || bossType == .love || bossType == .disgust ? 0.7 : 0.8)
        let moveDown = SKAction.moveTo(y: finalHeight, duration: 2.0)
        moveDown.timingMode = .easeOut
        
        let sequence = SKAction.sequence([
            SKAction.group([moveDown, SKAction.fadeIn(withDuration: 2.0)]),
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.physicsBody?.categoryBitMask = 0x1 << 4
                self?.physicsBody?.contactTestBitMask = 0x1 << 1
                self?.canShoot = true
            }
        ])
        
        run(sequence)
    }
    
    private func handleLoveMovement(currentTime: TimeInterval, in scene: SKScene) {
        let time = currentTime * 0.3
        let radiusX: CGFloat = 150
        let radiusY: CGFloat = 80
        let centerX = scene.size.width / 2
        let centerY = scene.size.height * 0.7
        
        let targetX = centerX + radiusX * cos(time)
        let targetY = centerY + radiusY * sin(2 * time)
        
        let smoothing: CGFloat = 0.05
        position = CGPoint(
            x: position.x + (targetX - position.x) * smoothing,
            y: position.y + (targetY - position.y) * smoothing
        )
        
        
        // Update existing shields
        rotateShields(currentTime: currentTime)
    }
    
    private func shootHomingHeart(in scene: SKScene) {
        guard let player = scene.childNode(withName: "testPlayer") else { return }
        
        let heart = SKSpriteNode(imageNamed: "heart")
        heart.size = CGSize(width: 20, height: 20)
        heart.name = "enemyBullet"
        heart.position = position
        
        heart.physicsBody = SKPhysicsBody(rectangleOf: heart.size)
        heart.physicsBody?.categoryBitMask = 0x1 << 3
        heart.physicsBody?.contactTestBitMask = 0x1 << 0
        heart.physicsBody?.collisionBitMask = 0
        heart.physicsBody?.affectedByGravity = false
        
        scene.addChild(heart)
        
        // Calculate initial direction towards player with some randomness
        let dx = player.position.x - position.x
        let dy = player.position.y - position.y
        let angle = atan2(dy, dx)
        let randomSpread = CGFloat.random(in: -0.3...0.3)
        let finalAngle = angle + randomSpread
        
        let initialSpeed: CGFloat = 200
        let homingSpeed: CGFloat = 300
        let screenDiagonal = hypot(scene.size.width, scene.size.height)
        
        let initialMove = SKAction.move(by: CGVector(
            dx: cos(finalAngle) * initialSpeed,
            dy: sin(finalAngle) * initialSpeed
        ), duration: 1.0)
        
        let wait = SKAction.wait(forDuration: 1.0)
        
        let targetPosition = player.position
        let homingMove = SKAction.move(by: CGVector(
            dx: cos(finalAngle) * screenDiagonal,
            dy: sin(finalAngle) * screenDiagonal
        ), duration: screenDiagonal / homingSpeed)
        
        heart.run(SKAction.sequence([initialMove, wait, homingMove, SKAction.removeFromParent()]))
        
        playSoundEffect(named: "loveShoot.mp3")

    }
    
    private func createHeartShields() {
        let shieldCount = 20
        let radius: CGFloat = 100
        
        for i in 0..<shieldCount {
            let angle = (CGFloat(i) / CGFloat(shieldCount)) * CGFloat.pi * 2
            
            let shield = SKSpriteNode(imageNamed: "heartShield")
            shield.size = CGSize(width: 20, height: 20)
            shield.name = "heartShield"
            shield.zPosition = 1
            shield.position = CGPoint(
                x: position.x + radius * cos(angle),
                y: position.y + radius * sin(angle)
            )
            
            // Store the initial angle in userData
            shield.userData = ["baseAngle": angle]
            
            shield.physicsBody = SKPhysicsBody(rectangleOf: shield.size)
            shield.physicsBody?.categoryBitMask = 0x1 << 5
            shield.physicsBody?.contactTestBitMask = 0x1 << 1
            shield.physicsBody?.collisionBitMask = 0
            shield.physicsBody?.isDynamic = false
            
            scene?.addChild(shield)
            heartShields.append(shield)
        }
    }
    
    private func rotateShields(currentTime: TimeInterval) {
        let radius: CGFloat = 100
        let rotationSpeed: CGFloat = 1.5
        
        for shield in heartShields {
            // Use the shield's current base angle instead of recalculating based on index
            if let baseAngle = shield.userData?["baseAngle"] as? CGFloat {
                let rotationAngle = baseAngle + (currentTime * rotationSpeed)
                
                shield.position = CGPoint(
                    x: position.x + radius * cos(rotationAngle),
                    y: position.y + radius * sin(rotationAngle)
                )
                shield.zRotation = rotationAngle
            }
        }
    }
    
    func handleShieldHit(_ shield: SKNode) {
        shieldDamageCount[shield, default: 0] += 1
        
        if shieldDamageCount[shield, default: 0] >= 2 {
            shield.removeFromParent()
            playSoundEffect(named: "loveShield.mp3")
            heartShields.removeAll { $0 == shield }
            shieldDamageCount.removeValue(forKey: shield)
        } else {
            shield.run(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            playSoundEffect(named: "loveShield.mp3")

        }
    }
    
    private func createHeartBurst(in scene: SKScene) {
        let heartCount = 8
        let radius: CGFloat = 100
        
        for i in 0..<heartCount {
            let angle = (CGFloat(i) / CGFloat(heartCount)) * CGFloat.pi * 2
            let position = CGPoint(
                x: self.position.x + radius * cos(angle),
                y: self.position.y + radius * sin(angle)
            )
            
            let heart = SKShapeNode(rect: CGRect(x: -15, y: -15, width: 30, height: 30), cornerRadius: 7.5)
            heart.fillColor = .systemPink
            heart.strokeColor = .red
            heart.name = "enemyBullet"
            heart.position = position
            heart.zRotation = angle + .pi / 4
            
            heart.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 30))
            heart.physicsBody?.categoryBitMask = 0x1 << 3
            heart.physicsBody?.contactTestBitMask = 0x1 << 0
            heart.physicsBody?.collisionBitMask = 0
            heart.physicsBody?.affectedByGravity = false
            
            scene.addChild(heart)
            
            // Pulsing animation
            let scale = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])
            
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
            
            heart.run(SKAction.group([
                SKAction.repeatForever(scale),
                SKAction.repeatForever(rotate)
            ]))
            
            // Gradually expand outward
            let expandDuration: TimeInterval = 3.0
            let expandAction = SKAction.customAction(withDuration: expandDuration) { node, elapsedTime in
                let progress = elapsedTime / CGFloat(expandDuration)
                let currentRadius = radius * (1 + progress)
                node.position = CGPoint(
                    x: self.position.x + currentRadius * cos(angle),
                    y: self.position.y + currentRadius * sin(angle)
                )
            }
            
            heart.run(SKAction.sequence([
                expandAction,
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    func cleanup() {
        // Add this at the start of the existing cleanup function
        healthBarContainer?.removeFromParent()
        healthBarContainer = nil
        
        // Rest of your existing cleanup code...
        for shield in heartShields {
            shield.removeFromParent()

        }
        heartShields.removeAll()
        shieldHealth.removeAll()
        
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
        playSoundEffect(named: "sadnessShoot.mp3") // maybe replace this one
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
        
        // Remove the collision enabling code from here since it's now in the animation sequence
        if timeSinceEntry > 3.0 {
            if !isSwooping {
                if bossType == .sadness {
                    handleSadnessMovement(currentTime: currentTime, in: scene)
                } else if bossType == .anger {
                    handleAngerMovement(currentTime: currentTime, in: scene)
                    // Only shoot if not stomping and enough time has passed
                    if currentTime - lastShootTime >= 3.0 && !isSwooping {
                        shootFireballPattern(in: scene)
                        lastShootTime = currentTime
                    }
                } else if bossType == .disgust {
                    handleDisgustMovement(currentTime: currentTime, in: scene)
                } else if bossType == .love {
                    handleLoveMovement(currentTime: currentTime, in: scene)
                    if currentTime - lastShootTime >= 1.2 {
                        shootHomingHeart(in: scene)
                        lastShootTime = currentTime
                    }
                    
                    // Create shields after entry animation
                    if timeSinceEntry > 3.0 && !shieldsHaveBeenCreated {
                        createHeartShields()
                        shieldsHaveBeenCreated = true
                    }
                    rotateShields(currentTime: currentTime)
                }
            }
        }
    }
    
    func damageShield(_ shield: SKNode) {
        shieldHits[shield, default: 0] += 1
        
        if shieldHits[shield, default: 0] >= 4 {
            shield.removeFromParent()
            playSoundEffect(named: "loveShield1.mp3")

            heartShields.removeAll { $0 == shield }
            shieldHits.removeValue(forKey: shield)
        } else {
            shield.run(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.colorize(with: .white, colorBlendFactor: 0.5, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
            ]))
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
        // Create main toxic cloud
        let cloud = SKShapeNode(ellipseOf: CGSize(width: 60, height: 40))
        cloud.fillColor = .init(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.5)
        cloud.strokeColor = .green
        cloud.alpha = 0.7
        cloud.position = position
        cloud.zPosition = 1
        
        // Add toxic effect
        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 5.0])
        
        let glowShape = SKShapeNode(ellipseOf: CGSize(width: 60, height: 40))
        glowShape.fillColor = .green
        glowShape.strokeColor = .clear
        glow.addChild(glowShape)
        cloud.addChild(glow)
        
        scene.addChild(cloud)
        slimeTrail.append(cloud)
        
        // Deadly collision
        cloud.physicsBody = SKPhysicsBody(circleOfRadius: 25)  // Smaller collision radius
        cloud.physicsBody?.categoryBitMask = 0x1 << 3  // Same as enemy bullets
        cloud.physicsBody?.contactTestBitMask = 0x1 << 0  // Player category
        cloud.physicsBody?.collisionBitMask = 0
        cloud.physicsBody?.isDynamic = false
        
        // Animation
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ])
        
        cloud.run(sequence) { [weak self] in
            self?.slimeTrail.removeFirst()
        }
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
        
        playSoundEffect(named: "disgustShoot.mp3")
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
        if currentTime - entryStartTime > 3.0 {
            if !isSwooping && currentTime - lastSwoopTime >= 5.0 {
                startSwoop(in: scene)
                playSoundEffect(named: "angerDive.mp3")
                lastSwoopTime = currentTime
                lastShootTime = currentTime
            } else if !isSwooping {
                let moveSpeed: CGFloat = 2.0
                let targetX = position.x + moveSpeed * moveDirection
                position.x = targetX
                
                if position.x >= scene.size.width - 80 {
                    moveDirection = -1
                } else if position.x <= 80 {
                    moveDirection = 1
                }
                
                // Adjusted height values
                let maxHeight = scene.size.height * 0.7  // Lower maximum height
                let minHeight = maxHeight - 30
                verticalOffset = sin(currentTime * 2) * 15
                position.y = min(maxHeight, max(minHeight, normalHeight + verticalOffset))
            }
        }
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
        playSoundEffect(named: "disgustRing.mp3")
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
        // Make Anger swoop to bottom of screen
        let moveDown = SKAction.moveTo(y: scene.size.height * 0.15, duration: 0.5)  // Lower value for bottom of screen
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
            let fireball = SKSpriteNode(imageNamed: "Fireball")
            fireball.size = CGSize(width: 24, height: 24)
            fireball.name = "enemyBullet"
            
            // Create glow effect
            let glowEffect = SKEffectNode()
            glowEffect.shouldRasterize = true
            glowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
            
            let glowSprite = SKSpriteNode(imageNamed: "Fireball")
            glowSprite.size = fireball.size
            glowSprite.color = .yellow
            glowSprite.colorBlendFactor = 1.0
            glowSprite.alpha = 0.6
            glowEffect.addChild(glowSprite)
            fireball.addChild(glowEffect)
            glowEffect.zPosition = -1
            
            fireball.position = position
            fireball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
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
            
            // Calculate the angle for the fireball's rotation
            // Add π/2 because the sprite's default orientation might need adjustment
            let moveAngle = atan2(dy, dx) + .pi/2
            fireball.zRotation = moveAngle
            
            let moveDistance = scene.size.height + 100
            let moveDuration = moveDistance / bulletSpeed
            
            let moveVector = CGVector(dx: dx * moveDuration, dy: -moveDistance)
            let moveAction = SKAction.move(by: moveVector, duration: moveDuration)
            
            fireball.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
            
            playSoundEffect(named: "angerShoot.mp3")
        }
    }
}

extension UIDevice {
    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first
            let safeAreaInsets = window?.safeAreaInsets
            return safeAreaInsets?.top ?? 0 > 20
        }
        return false
    }
}
