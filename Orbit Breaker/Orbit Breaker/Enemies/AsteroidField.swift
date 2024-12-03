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
        
        // Warning text - adjusted position and multiline
        let warningLabel = SKLabelNode(fontNamed: "Arial-Bold")
        warningLabel.numberOfLines = 2
        warningLabel.text = "ASTEROID FIELD\n APPROACHING!"
        warningLabel.fontSize = 40
        warningLabel.fontColor = .red
        warningLabel.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        warningLabel.verticalAlignmentMode = .center
        warningLabel.horizontalAlignmentMode = .center
        warningLabel.alpha = 0
        warningLabel.zPosition = 101
        scene.addChild(warningLabel)
        
        // Flash effect
        let flashSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.fadeAlpha(to: 0.3, duration: 0.3)
        ])
        
        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.5),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        warningLabel.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.repeat(flashSequence, count: 3),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent(),
            SKAction.run { completion() }
        ]))
    }
}

class AsteroidFieldChallenge {
    private weak var scene: SKScene?
    private var asteroids: [SKNode] = []
    
    init(scene: SKScene) {
        self.scene = scene
    }
    private func createAsteroid(at position: CGPoint) -> SKNode {
        let asteroid = SKShapeNode(circleOfRadius: 20)
        asteroid.fillColor = .gray
        asteroid.strokeColor = .white
        asteroid.position = position
        asteroid.name = "asteroid"
        
        // Physics setup
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        asteroid.physicsBody?.categoryBitMask = 0x1 << 6 // New category
        asteroid.physicsBody?.contactTestBitMask = 0x1 << 0 // Player
        asteroid.physicsBody?.collisionBitMask = 0
        
        // Rotation animation
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        asteroid.run(SKAction.repeatForever(rotate))
        
        scene?.addChild(asteroid)
        asteroids.append(asteroid)
        
        // Move down
        let moveDown = SKAction.moveBy(x: 0, y: -(scene?.size.height ?? 0) - 100, duration: 4.0)
        asteroid.run(SKAction.sequence([moveDown, SKAction.removeFromParent()]))
        
        return asteroid
    }
    
    // Different asteroid patterns
    private func createTopWall() {
           guard let scene = scene else { return }
           let gap = 200.0 // Increased gap size
           let gapPosition = scene.size.width/2
           
           for x in stride(from: 0.0, through: scene.size.width, by: 60.0) {
               if abs(x - gapPosition) > gap/2 {
                   createAsteroid(at: CGPoint(x: x, y: scene.size.height + 50))
               }
           }
       }
       
       private func createDiagonalPattern() {
           guard let scene = scene else { return }
           
           // Create gaps in the diagonal line
           let gapStart = Int.random(in: 2...5)
           for i in 0...8 {
               // Skip 2 positions to create a gap
               if i != gapStart && i != gapStart + 1 {
                   let x = scene.size.width * CGFloat(i) / 8.0
                   createAsteroid(at: CGPoint(x: x, y: scene.size.height + 50))
               }
           }
       }
       
       private func createZigZagPattern() {
           guard let scene = scene else { return }
           let centerX = scene.size.width/2
           
           // Create a zigzag with clear gaps
           let positions = [
               CGPoint(x: centerX - 180, y: scene.size.height + 50),
               CGPoint(x: centerX - 90, y: scene.size.height + 100),
               CGPoint(x: centerX, y: scene.size.height + 50),
               CGPoint(x: centerX + 90, y: scene.size.height + 100),
               CGPoint(x: centerX + 180, y: scene.size.height + 50)
           ]
           
           // Skip middle asteroid to create guaranteed passage
           for (index, position) in positions.enumerated() {
               if index != 2 { // Skip center asteroid
                   createAsteroid(at: position)
               }
           }
       }
       
       private func createNarrowPassage() {
           guard let scene = scene else { return }
           let passageWidth = 150.0 // Increased passage width
           let centerX = scene.size.width/2
           
           // Create two walls with a wider passage
           for x in stride(from: 0.0, to: centerX - passageWidth/2, by: 60.0) {
               createAsteroid(at: CGPoint(x: x, y: scene.size.height + 50))
           }
           
           for x in stride(from: centerX + passageWidth/2, to: scene.size.width, by: 60.0) {
               createAsteroid(at: CGPoint(x: x, y: scene.size.height + 50))
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
            let leftWall = createWallSection(at: scene.size.width * 0.25,
                                           width: scene.size.width * 0.25,
                                           spacing: 60)
            
            // Right wall offset
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let rightWall = self.createWallSection(at: scene.size.width * 0.75,
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
            let patterns = [
                SKAction.run { [weak self] in self?.createSweepingGate() },
                SKAction.run { [weak self] in self?.createSimpleSpiral() },
                SKAction.run { [weak self] in self?.createAlternatingWalls() },
                SKAction.run { [weak self] in self?.createSinglePendulum() }
            ]
            
            // Choose 3 random patterns with longer delays between them
            let selectedPatterns = patterns.shuffled().prefix(3).map { pattern in
                SKAction.sequence([
                    pattern,
                    SKAction.wait(forDuration: 4.0) // Increased delay between patterns
                ])
            }
            
            let sequence = SKAction.sequence(selectedPatterns + [
                SKAction.wait(forDuration: 2.0),
                SKAction.run { completion() }
            ])
            
            scene?.run(sequence)
        }
    
    func cleanup() {
        asteroids.forEach { $0.removeFromParent() }
        asteroids.removeAll()
    }
}
