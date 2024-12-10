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
    
    func showAnnouncement(completion: @escaping () -> Void) {
        guard let scene = scene else { return }
        
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
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    private func createAsteroid(at position: CGPoint, withMove moveAction: SKAction? = nil) -> SKNode {
           let asteroid = SKShapeNode(circleOfRadius: 20)
           asteroid.fillColor = .gray
           asteroid.strokeColor = .white
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
               // Add completion handler to remove from asteroids array
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
    
    // New formation: Rotating Cross
    private func createRotatingCross() {
        guard let scene = scene else { return }
        let centerX = scene.size.width/2
        let spacing: CGFloat = 70
        
        for i in -2...2 {
            guard i != 0 else { continue } // Skip center for gap
            // Horizontal line
            let hAsteroid = createAsteroid(at: CGPoint(x: centerX + CGFloat(i) * spacing,
                                                      y: scene.size.height + 50))
            // Vertical line
            let vAsteroid = createAsteroid(at: CGPoint(x: centerX,
                                                      y: scene.size.height + 50 + CGFloat(i) * spacing))
            
            let rotateAroundCenter = SKAction.customAction(withDuration: 4.0) { node, time in
                let progress = time / 4.0
                let angle = progress * .pi * 2
                let radius = spacing * CGFloat(abs(i))
                node.position.x = centerX + cos(angle) * radius
                node.position.y = (scene.size.height + 50) - time * 100 + sin(angle) * radius
            }
            
            hAsteroid.run(SKAction.sequence([rotateAroundCenter, SKAction.removeFromParent()]))
            vAsteroid.run(SKAction.sequence([rotateAroundCenter, SKAction.removeFromParent()]))
        }
    }
    
    private func createWavePattern() {
        guard let scene = scene else { return }
        let startY: CGFloat = scene.size.height + 100 // Explicitly declare as CGFloat
        let endY: CGFloat = -100.0 // Explicitly declare as CGFloat
        let duration = 5.0
        
        for i in 0...8 {
            guard i < 3 || i > 5 else { continue }
            
            let x = scene.size.width * CGFloat(i) / 8.0
            // Break up the complex expression into smaller parts
            let moveAction = SKAction.customAction(withDuration: duration) { [weak self] node, time in
                let progress = CGFloat(time) / CGFloat(duration)
                let totalDistance = startY - endY
                let currentY = startY - (progress * totalDistance)
                let waveOffset = sin(CGFloat(time) * 2.0) * 50.0
                node.position.y = currentY
                node.position.x = x + waveOffset
            }
            
            createAsteroid(at: CGPoint(x: x, y: startY), withMove: moveAction)
        }
    }

    private func createDoubleHelix() {
        guard let scene = scene else { return }
        let startY: CGFloat = scene.size.height + 100
        let endY: CGFloat = -100.0
        let duration = 5.0
        let gapWidth: CGFloat = 180
        
        for i in 0...12 {
            let progress = CGFloat(i) / 12.0
            let yOffset = CGFloat(i) * 50.0
            
            for side in [-1, 1] {
                let centerX = scene.size.width/2
                let sideOffset = gapWidth/2 * CGFloat(side)
                let x = centerX + sideOffset
                
                // Break up the complex movement calculation
                let moveAction = SKAction.customAction(withDuration: duration) { [weak self] node, time in
                    let timeProgress = CGFloat(time) / CGFloat(duration)
                    let distance = startY - endY + yOffset
                    let currentY = startY + yOffset - (timeProgress * distance)
                    let angle = (currentY + CGFloat(time) * 100) * .pi / 180
                    let xOffset = sin(angle) * 50
                    node.position = CGPoint(x: x + xOffset, y: currentY)
                }
                
                createAsteroid(at: CGPoint(x: x, y: startY + yOffset), withMove: moveAction)
            }
        }
    }
    
    // New formation: Expanding Circle
    private func createExpandingCircle() {
        guard let scene = scene else { return }
        let centerX = scene.size.width/2
        let asteroidCount = 8
        let radius: CGFloat = 100
        
        for i in 0..<asteroidCount {
            // Create a gap in the circle
            guard i != 0 else { continue }
            
            let angle = (CGFloat(i) / CGFloat(asteroidCount)) * .pi * 2
            let x = centerX + radius * cos(angle)
            let y = scene.size.height + 50 + radius * sin(angle)
            
            let asteroid = createAsteroid(at: CGPoint(x: x, y: y))
            
            let expandAndDescend = SKAction.customAction(withDuration: 4.0) { node, time in
                let expandingRadius = radius + (time * 50)
                node.position.x = centerX + expandingRadius * cos(angle)
                node.position.y = (scene.size.height + 50) - time * 100 + expandingRadius * sin(angle)
            }
            
            asteroid.run(SKAction.sequence([expandAndDescend, SKAction.removeFromParent()]))
        }
    }

    private func createSweepingGate() {
            guard let scene = scene else { return }
            let centerX = scene.size.width/2
            let gateWidth: CGFloat = 200 // Extra wide gap for moving formation
            
            // Create two groups of asteroids that sweep side to side
            for side in [-1, 1] {
                for i in 0...2 {
                    let xOffset = CGFloat(i) * 60
                    let x = centerX + (gateWidth/2 * CGFloat(side)) + (xOffset * CGFloat(side))
                    let asteroid = createAsteroid(at: CGPoint(x: x, y: scene.size.height + 50))
                    
                    // Gentle sweeping motion
                    let sweep = SKAction.sequence([
                        SKAction.moveBy(x: -50 * CGFloat(side), y: -200, duration: 1.5),
                        SKAction.moveBy(x: 50 * CGFloat(side), y: -200, duration: 1.5)
                    ])
                    asteroid.run(sweep)
                }
            }
        }
        
        private func createSimpleSpiral() {
            guard let scene = scene else { return }
            let centerX = scene.size.width/2
            let radius: CGFloat = 150 // Increased radius
            let asteroidCount = 6 // Fewer asteroids
            
            for i in 0..<asteroidCount {
                // Create a big gap in the spiral
                guard i != 2 && i != 3 else { continue }
                
                let angle = (CGFloat(i) / CGFloat(asteroidCount)) * .pi * 2
                let x = centerX + radius * cos(angle)
                let y = scene.size.height + radius * sin(angle)
                
                let asteroid = createAsteroid(at: CGPoint(x: x, y: y))
                
                // Slower rotation
                let moveDown = SKAction.moveBy(x: 0, y: -(scene.size.height + radius * 2), duration: 5.0)
                let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 5.0)
                asteroid.run(SKAction.group([moveDown, rotate]))
            }
        }
        
        private func createAlternatingWalls() {
            guard let scene = scene else { return }
            let gapWidth: CGFloat = 250 // Very wide gap
            
            // Left wall
            let leftWall: () = createWallSection(at: scene.size.width * 0.25,
                                           width: scene.size.width * 0.25,
                                           spacing: 60)
            
            // Right wall offset
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let rightWall: () = self.createWallSection(at: scene.size.width * 0.75,
                                                     width: scene.size.width * 0.25,
                                                     spacing: 60)
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
        
        private func createSinglePendulum() {
            guard let scene = scene else { return }
            let centerX = scene.size.width/2
            let gapWidth: CGFloat = 200 // Wide gap
            
            // Create just two asteroids that swing in opposite directions
            for side in [-1, 1] {
                let xPos = centerX + (gapWidth/2 * CGFloat(side))
                let asteroid = createAsteroid(at: CGPoint(x: xPos, y: scene.size.height + 50))
                
                // Gentle swinging motion
                let swing = SKAction.sequence([
                    SKAction.moveBy(x: 60 * CGFloat(side), y: -150, duration: 1.5),
                    SKAction.moveBy(x: -60 * CGFloat(side), y: -150, duration: 1.5)
                ])
                
                asteroid.run(SKAction.sequence([
                    SKAction.repeat(swing, count: 2),
                    SKAction.removeFromParent()
                ]))
            }
        }
        
    
    func startChallenge(completion: @escaping () -> Void) {
            isActive = true
            cleanup() // Clean up any existing asteroids
            
            // Disable player shields at start
            if let gameScene = scene as? GameScene {
                gameScene.user?.removeShield()
            }
            
            let patterns = [
                SKAction.run { [weak self] in self?.createWavePattern() },
                SKAction.run { [weak self] in self?.createDoubleHelix() }
                // Add other pattern functions here
            ]
            
            let selectedPatterns = patterns.shuffled().prefix(4).map { pattern in
                SKAction.sequence([
                    pattern,
                    SKAction.wait(forDuration: Double.random(in: 4.0...5.0))
                ])
            }
            
            let sequence = SKAction.sequence(selectedPatterns + [
                SKAction.wait(forDuration: 2.0),
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
