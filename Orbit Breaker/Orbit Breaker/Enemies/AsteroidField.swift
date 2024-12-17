//
//  AsteroidField.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/30/24.
//

import SpriteKit


class AsteroidFieldAnnouncement {
    private weak var scene: SKScene?
    
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func playSoundEffect(named soundName: String) {
        SoundManager.shared.playSound(soundName)
    }
    
    
    func showAnnouncement(completion: @escaping () -> Void) {
        guard let scene = scene else { return }
        playSoundEffect(named: "announcementSound.mp3") // Replace with your sound file name

        // Create dark overlay
        let overlay = SKShapeNode(rectOf: scene.size)
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.alpha = 0
        overlay.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        overlay.zPosition = 100
        scene.addChild(overlay)
        
        // Simple container for text
        let container = SKNode()
        container.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        container.zPosition = 101
        scene.addChild(container)
        
        // Create background for text
        let textBackground = SKShapeNode(rectOf: CGSize(width: 400, height: 100))
        textBackground.fillColor = SKColor(white: 0.1, alpha: 1.0)
        textBackground.strokeColor = .red
        textBackground.lineWidth = 2
        textBackground.alpha = 0
        container.addChild(textBackground)
        
        // Warning text
        let warningLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        warningLabel.text = "ASTEROID FIELD"
        warningLabel.fontSize = 36
        warningLabel.fontColor = .white
        warningLabel.position = CGPoint(x: 0, y: 10)
        warningLabel.alpha = 0
        container.addChild(warningLabel)
        
        // Approaching text
        let approachingLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        approachingLabel.text = "APPROACHING"
        approachingLabel.fontSize = 28
        approachingLabel.fontColor = .red
        approachingLabel.position = CGPoint(x: 0, y: -25)
        approachingLabel.alpha = 0
        container.addChild(approachingLabel)
        
        // Simple flash animation
        let flashSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.2),
            SKAction.fadeAlpha(to: 0.5, duration: 0.2)
        ])
        
        // Run animations
        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.3),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        textBackground.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3)
        ]))
        
        let textAppear = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.repeat(flashSequence, count: 3)
        ])
        
        warningLabel.run(textAppear)
        approachingLabel.run(textAppear)
        
        // Clean up and complete
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent(),
            SKAction.run {
                completion()
            }
        ]))
    }
}

class AsteroidFieldChallenge {
    private weak var scene: SKScene?
    private var asteroids: [SKNode] = []
       private var isActive = false
    private var formationFunctions: [(SKScene) -> Void] = []
    private var isDebugging = true

    private func checkPosition(node: SKNode, label: String) {
        guard isDebugging, let scene = scene else { return }
        if node.position.y > scene.size.height {
            print("\(label): Above screen at y: \(node.position.y)")
        } else if node.position.y < -100 {
            print("\(label): Below screen at y: \(node.position.y)")
        } else {
            print("\(label): VISIBLE ON SCREEN at y: \(node.position.y)")
        }
    }

    init(scene: SKScene) {
        self.scene = scene
        
        // Initialize all formation functions
        formationFunctions = [
            { [weak self] scene in self?.createRotatingCross() },
            { [weak self] scene in self?.createExpandingCircle() },
            { [weak self] scene in self?.createSweepingGate() },
            { [weak self] scene in self?.createSimpleSpiral() },
            { [weak self] scene in self?.createAlternatingWalls() },
            { [weak self] scene in self?.createSinglePendulum() }
        ]
    }
    
    private func createAsteroid(at position: CGPoint, withMove moveAction: SKAction? = nil) -> SKNode {
        let asteroid = SKSpriteNode(imageNamed: "Asteroid\(Int.random(in: 1...3))")
        asteroid.size = CGSize(width: 40, height: 40) // Adjust size as needed
        asteroid.position = position
        asteroid.name = "asteroid"
        
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        asteroid.physicsBody?.categoryBitMask = 0x1 << 6
        asteroid.physicsBody?.contactTestBitMask = 0x1 << 0
        asteroid.physicsBody?.collisionBitMask = 0
        
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: Double.random(in: 1.5...3.0))
        asteroid.run(SKAction.repeatForever(rotate))
        
        scene?.addChild(asteroid)
        asteroids.append(asteroid)
        
        if let moveAction = moveAction {
            let sequence = SKAction.sequence([
                moveAction,
                SKAction.run { [weak self] in
                    if let index = self?.asteroids.firstIndex(of: asteroid) {
                        self?.asteroids.remove(at: index)
                    }
                },
                SKAction.removeFromParent()
            ])
            asteroid.run(sequence)
        }
        
        return asteroid
    }
    


    private func createRotatingCross() {
        guard let scene = scene else { return }
        let centerX = scene.size.width/2
        let spacing: CGFloat = 70
        let startY = scene.size.height + 150 // Increased offset
        let totalDistance = scene.size.height + 400 // Increased travel distance
        
        for i in -2...2 {
            guard i != 0 else { continue }
            let hAsteroid = createAsteroid(at: CGPoint(x: centerX + CGFloat(i) * spacing, y: startY))
            let vAsteroid = createAsteroid(at: CGPoint(x: centerX, y: startY + CGFloat(i) * spacing))
            
            let rotateAroundCenter = SKAction.customAction(withDuration: 6.0) { [weak self] node, time in
                let progress = time / 6.0
                let angle = progress * .pi * 2
                let radius = spacing * CGFloat(abs(i))
                node.position.x = centerX + cos(angle) * radius
                node.position.y = startY - (time * (totalDistance / 6.0))
                
                if self?.isDebugging == true {
                    self?.checkPosition(node: node, label: "Cross")
                }
            }
            
            let sequence = SKAction.sequence([rotateAroundCenter, SKAction.removeFromParent()])
            hAsteroid.run(sequence)
            vAsteroid.run(sequence)
        }
    }

    private func createExpandingCircle() {
        guard let scene = scene else { return }
        let centerX = scene.size.width/2
        let asteroidCount = 8
        let radius: CGFloat = 100
        let startY = scene.size.height + 150 // Increased offset
        let totalDistance = scene.size.height + 400 // Increased travel distance
        
        for i in 0..<asteroidCount {
            guard i != 0 else { continue }
            
            let angle = (CGFloat(i) / CGFloat(asteroidCount)) * .pi * 2
            let x = centerX + radius * cos(angle)
            let y = startY + radius * sin(angle)
            
            let asteroid = createAsteroid(at: CGPoint(x: x, y: y))
            
            let expandAndDescend = SKAction.customAction(withDuration: 6.0) { [weak self] node, time in
                let expandingRadius = radius + (time * 50)
                node.position.x = centerX + expandingRadius * cos(angle)
                node.position.y = startY - (time * (totalDistance / 6.0))
                
                if self?.isDebugging == true {
                    self?.checkPosition(node: node, label: "Circle \(i)")
                }
            }
            
            asteroid.run(SKAction.sequence([expandAndDescend, SKAction.removeFromParent()]))
        }
    }

    private func createSweepingGate() {
        guard let scene = scene else { return }
        let centerX = scene.size.width/2
        let gateWidth: CGFloat = 200
        let startY = scene.size.height + 50
        
        for side in [-1, 1] {
            for i in 0...2 {
                let xOffset = CGFloat(i) * 60
                let x = centerX + (gateWidth/2 * CGFloat(side)) + (xOffset * CGFloat(side))
                let asteroid = createAsteroid(at: CGPoint(x: x, y: startY))
                
                let moveDown = SKAction.moveBy(x: 0, y: -(scene.size.height + 200), duration: 6.0)
                let sweep = SKAction.sequence([
                    SKAction.moveBy(x: -50 * CGFloat(side), y: 0, duration: 1.5),
                    SKAction.moveBy(x: 50 * CGFloat(side), y: 0, duration: 1.5)
                ])
                
                asteroid.run(SKAction.group([
                    moveDown,
                    SKAction.repeat(sweep, count: 2),
                    SKAction.sequence([
                        SKAction.wait(forDuration: 6.0),
                        SKAction.removeFromParent()
                    ])
                ]))
            }
        }
    }

    private func createSimpleSpiral() {
        guard let scene = scene else { return }
        let centerX = scene.size.width/2
        let radius: CGFloat = 150
        let asteroidCount = 6
        let startY = scene.size.height + 50
        
        for i in 0..<asteroidCount {
            guard i != 2 && i != 3 else { continue }
            
            let angle = (CGFloat(i) / CGFloat(asteroidCount)) * .pi * 2
            let x = centerX + radius * cos(angle)
            let y = startY + radius * sin(angle)
            
            let asteroid = createAsteroid(at: CGPoint(x: x, y: y))
            
            let moveDown = SKAction.moveBy(x: 0, y: -(scene.size.height + 200), duration: 6.0)
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 5.0)
            asteroid.run(SKAction.group([
                moveDown,
                SKAction.repeat(rotate, count: 2),
                SKAction.sequence([
                    SKAction.wait(forDuration: 6.0),
                    SKAction.removeFromParent()
                ])
            ]))
        }
    }

    private func createAlternatingWalls() {
        guard let scene = scene else { return }
        let startY = scene.size.height + 50
        let wallWidth: CGFloat = 200
        let asteroidSpacing: CGFloat = 60
        let minGapWidth: CGFloat = 100 // Minimum guaranteed gap width
        let maxGapWidth: CGFloat = 150 // Maximum gap width to ensure challenge
        
        print("deploying alternating walls")
        
        func createWall(at xPosition: CGFloat, delay: TimeInterval = 0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                print("Creating wall at xPosition: \(xPosition), delay: \(delay)")
                
                // Calculate the range of positions where asteroids are placed
                let startX = xPosition - wallWidth / 2
                let endX = xPosition + wallWidth / 2
                
                // Calculate available space for gap placement
                let availableSpace = endX - startX - minGapWidth
                guard availableSpace >= 0 else {
                    print("Warning: Wall width too narrow for minimum gap width")
                    return
                }
                
                // Randomly choose gap width between minimum and maximum
                let actualGapWidth = CGFloat.random(in: minGapWidth...min(maxGapWidth, availableSpace + minGapWidth))
                
                // Randomly choose a position for the gap, ensuring it fits within wall bounds
                let maxGapStart = endX - actualGapWidth
                let gapStart = CGFloat.random(in: startX...maxGapStart)
                let gapEnd = gapStart + actualGapWidth
                
                print("Gap range: \(gapStart) to \(gapEnd)")
                
                // Calculate number of possible asteroid positions
                let numberOfPossibleAsteroids = Int((wallWidth / asteroidSpacing).rounded(.down))
                guard numberOfPossibleAsteroids > 0 else {
                    print("Warning: Wall width too narrow for asteroid spacing")
                    return
                }
                
                // Place asteroids, skipping the gap
                for x in stride(from: startX, through: endX, by: asteroidSpacing) {
                    if x >= gapStart && x <= gapEnd {
                        print("Skipping asteroid at x: \(x) (within gap range)")
                        continue
                    }
                    
                    // Create and animate the asteroid
                    let asteroid = self.createAsteroid(at: CGPoint(x: x, y: startY))
                    let moveDown = SKAction.moveBy(x: 0, y: -(scene.size.height + 200), duration: 6.0)
                    asteroid.run(SKAction.sequence([moveDown, SKAction.removeFromParent()]))
                }
            }
        }
    }


    private func createSinglePendulum() {
        guard let scene = scene else { return }
        let centerX = scene.size.width/2
        let gapWidth: CGFloat = 200
        let startY = scene.size.height + 50
        
        for side in [-1, 1] {
            let xPos = centerX + (gapWidth/2 * CGFloat(side))
            let asteroid = createAsteroid(at: CGPoint(x: xPos, y: startY))
            
            let moveDown = SKAction.moveBy(x: 0, y: -(scene.size.height + 200), duration: 6.0)
            let swing = SKAction.sequence([
                SKAction.moveBy(x: 60 * CGFloat(side), y: 0, duration: 1.5),
                SKAction.moveBy(x: -60 * CGFloat(side), y: 0, duration: 1.5)
            ])
            
            asteroid.run(SKAction.group([
                moveDown,
                SKAction.repeat(swing, count: 2),
                SKAction.sequence([
                    SKAction.wait(forDuration: 6.0),
                    SKAction.removeFromParent()
                ])
            ]))
        }
    }
        
        private func createWallSection(at xPosition: CGFloat, width: CGFloat, spacing: CGFloat) {
            for x in stride(from: xPosition - width/2, through: xPosition + width/2, by: spacing) {
                let asteroid = createAsteroid(at: CGPoint(x: x, y: (scene?.size.height)! + 50))
                
                // Simple vertical movement
                let moveDown = SKAction.moveBy(x: 0, y: -(scene!.size.height + 100), duration: 4.0)
                asteroid.run(SKAction.sequence([moveDown, SKAction.removeFromParent()]))
            }
            
            return
        }
        
        
    
    func startChallenge(completion: @escaping () -> Void) {
        isActive = true
        cleanup()
        
        if let gameScene = scene as? GameScene {
            if gameScene.user.hasShield {
                gameScene.user?.removeShield()
                gameScene.powerUpManager?.hideShieldIndicator()
            }
        }
        
        let selectedFormations = formationFunctions.shuffled().prefix(5).map { formation in
            SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let scene = self?.scene else { return }
                    formation(scene)
                },
                SKAction.wait(forDuration: 3.5)
            ])
        }
        
        let sequence = SKAction.sequence(selectedFormations + [
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.isActive = false
                self?.cleanup()
                completion()
            }
        ])
        
        scene?.run(sequence)
    }
    
    func cleanup() {
            // Remove all asteroids and their actions
            for asteroid in asteroids {
                asteroid.removeAllActions()
                asteroid.removeFromParent()
            }
            asteroids.removeAll()
            
            // Remove any remaining asteroid-related actions from the scene
            scene?.removeAction(forKey: "asteroidSequence")
        }
}
