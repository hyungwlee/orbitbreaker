//
//  WaveRoadmap.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/30/24.
//
import SpriteKit
import UIKit

class WaveRoadmap {
    private weak var scene: SKScene?
    private var roadmapNodes: [SKNode] = []
    private var stageDots: [SKShapeNode] = []
    private var currentStageIndicator: SKShapeNode?
    private let stageCount = 6  // 5 stages + boss
    private var enemyManager: EnemyManager
    var screenHeight: Int
    var isiPhoneSE: Bool // SE (2nd gen) has 667 points height
    var layoutInfo: OBLayoutInfo
    
    init(scene: SKScene, enemyManager: EnemyManager, layoutInfo: OBLayoutInfo) {
       self.scene = scene
       self.enemyManager = enemyManager
       self.screenHeight = Int(UIScreen.main.bounds.height)
       self.layoutInfo = layoutInfo
       self.isiPhoneSE = screenHeight <= 667 // SE (2nd gen) has 667 points height
       setupRoadmap()
   }
    
    private func setupRoadmap() {
        guard let scene = scene else { return }
        
        // Ensure thorough cleanup before setting up
        cleanup()
        
        let spacing: CGFloat = 50 * layoutInfo.screenScaleFactor
        let dotRadius: CGFloat = 15 * layoutInfo.screenScaleFactor
        let centerX: CGFloat = 45 * layoutInfo.screenScaleFactor
        
        // Adjust margins based on device
        let topMargin: CGFloat = isiPhoneSE ? 30 : 80
        let startY = scene.size.height - topMargin - (CGFloat(stageCount - 1) * spacing)
        
        // Create connecting "space path" with enhanced visibility
        let path = CGMutablePath()
        path.move(to: CGPoint(x: centerX, y: startY))
        path.addLine(to: CGPoint(x: centerX, y: scene.size.height - topMargin))
            
        
        // Add glowing background to path
        let glowPath = SKShapeNode(path: path)
        glowPath.strokeColor = SKColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.2)
        glowPath.lineWidth = 12 * layoutInfo.screenScaleFactor  // Scale the line width
        glowPath.lineCap = .round
        glowPath.zPosition = 1
        
        let mainPath = SKShapeNode(path: path)
        mainPath.strokeColor = SKColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.4)
        mainPath.lineWidth = 4 * layoutInfo.screenScaleFactor  // Scale the line width
        mainPath.lineCap = .round
        mainPath.zPosition = 2
        
        scene.addChild(glowPath)
        scene.addChild(mainPath)
        roadmapNodes.append(glowPath)
        roadmapNodes.append(mainPath)
        
        // Add starfield effect
        let starsNode = SKNode()
        for _ in 0..<15 {
            let star = SKShapeNode(circleOfRadius: 1)
            star.fillColor = .white
            star.strokeColor = .white
            star.position = CGPoint(
                x: centerX + CGFloat.random(in: -15...15),
                y: startY + CGFloat.random(in: 0...spacing * CGFloat(stageCount - 1))
            )
            star.alpha = CGFloat.random(in: 0.3...0.8)
            starsNode.addChild(star)
            
            let twinkle = SKAction.sequence([
                SKAction.fadeOut(withDuration: CGFloat.random(in: 0.5...1.5)),
                SKAction.fadeIn(withDuration: CGFloat.random(in: 0.5...1.5))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
        scene.addChild(starsNode)
        roadmapNodes.append(starsNode)
        
        // Create stage indicators
        for i in 0..<stageCount {
            let y = startY + CGFloat(i) * spacing
            let stageContainer = SKNode()
            stageContainer.position = CGPoint(x: centerX, y: y)
            
            let stageMarker = createStageMarker(for: i, radius: dotRadius)
            stageContainer.addChild(stageMarker)
            stageDots.append(stageMarker)
            
            scene.addChild(stageContainer)
            roadmapNodes.append(stageContainer)
        }
        
            setupPlayerIndicator(startY: startY, centerX: centerX)
    }
    
    private func createStageMarker(for stage: Int, radius: CGFloat) -> SKShapeNode {
        let marker = SKShapeNode(circleOfRadius: radius)
        marker.lineWidth = 2
        marker.zPosition = 3
        
        if stage == stageCount - 1 {  // Boss stage
            // Base marker for consistent hit detection
            marker.fillColor = .clear
            marker.strokeColor = .clear
            
            // Add pulsing animation
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 1.0),
                SKAction.scale(to: 1.0, duration: 1.0)
            ])
        } else if stage == 2 {  // Asteroid field
            let asteroidPath = CGMutablePath()
            let points = 12
            var firstPoint = CGPoint.zero
            
            let radiusVariations: [CGFloat] = [1.0, 0.9, 1.1, 0.95, 1.05, 0.92, 1.08, 0.94, 1.06, 0.96, 1.04, 0.98]
            
            for i in 0..<points {
                let angle = CGFloat(i) * 2 * .pi / CGFloat(points)
                let asteroidRadius = radius * radiusVariations[i]
                let x = cos(angle) * asteroidRadius
                let y = sin(angle) * asteroidRadius
                
                if i == 0 {
                    firstPoint = CGPoint(x: x, y: y)
                    asteroidPath.move(to: firstPoint)
                } else {
                    asteroidPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            asteroidPath.addLine(to: firstPoint)
            
            marker.path = asteroidPath
            marker.fillColor = SKColor(red: 0.65, green: 0.63, blue: 0.62, alpha: 0.9)
            marker.strokeColor = SKColor(red: 0.75, green: 0.73, blue: 0.72, alpha: 1.0)
            
            let craterPositions: [(radius: CGFloat, x: CGFloat, y: CGFloat)] = [
                (0.25, 0.27, 0.3),
                (0.25, -0.33, 0.05),
                (0.25, 0.34, -0.3)
            ]
            
            for position in craterPositions {
                let crater = SKShapeNode(circleOfRadius: radius * position.radius)
                crater.position = CGPoint(x: radius * position.x, y: radius * position.y)
                crater.fillColor = SKColor(red: 0.55, green: 0.53, blue: 0.52, alpha: 0.7)
                crater.strokeColor = SKColor(red: 0.45, green: 0.43, blue: 0.42, alpha: 0.8)
                crater.name = "crater"  // Add name to identify craters
                marker.addChild(crater)
            }
        } else {  // Enemy waves
            marker.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.8)
            marker.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.6, alpha: 1.0)
            
            // Create UFO shape
            let ufoBody = SKShapeNode(ellipseOf: CGSize(width: radius * 1.6, height: radius * 0.8))
            ufoBody.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.7, alpha: 0.6)
            ufoBody.strokeColor = SKColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 0.8)
            
            // Add dome on top
            let dome = SKShapeNode(circleOfRadius: radius * 0.4)
            dome.position = CGPoint(x: 0, y: radius * 0.1)
            dome.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.6, alpha: 0.6)
            dome.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.7, alpha: 0.8)
            
            ufoBody.addChild(dome)
            marker.addChild(ufoBody)
            
            // Add subtle hover animation
            let hover = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 2, duration: 1.0),
                SKAction.moveBy(x: 0, y: -2, duration: 1.0)
            ])
            ufoBody.run(SKAction.repeatForever(hover))
        }
        
        return marker
    }
    
    
    private func setupPlayerIndicator(startY: CGFloat, centerX: CGFloat) {
        // Remove any existing indicator first
        currentStageIndicator?.removeAllActions()
        currentStageIndicator?.removeFromParent()
        currentStageIndicator = nil
        
        // Create triangular ship shape
        let shipPath = CGMutablePath()
        shipPath.move(to: CGPoint(x: 0, y: 12 * self.layoutInfo.screenScaleFactor))      // Top point
        shipPath.addLine(to: CGPoint(x: -8 * self.layoutInfo.screenScaleFactor,
                                     y: -6 * self.layoutInfo.screenScaleFactor))  // Bottom left
        shipPath.addLine(to: CGPoint(x: 8 * self.layoutInfo.screenScaleFactor,
                                     y: -6 * self.layoutInfo.screenScaleFactor))   // Bottom right
        shipPath.closeSubpath()
        
        let ship = SKShapeNode(path: shipPath)
        ship.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9)
        ship.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        ship.lineWidth = 2 * layoutInfo.screenScaleFactor
        ship.zPosition = 10
        ship.name = "playerIndicator"  // Add a name to help with cleanup
        
        // Add engine glow
        let engineGlow = SKShapeNode(path: CGMutablePath())
        engineGlow.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.6)
        engineGlow.strokeColor = .clear
        engineGlow.position = CGPoint(x: 0, y: -8 * layoutInfo.screenScaleFactor)
        
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.5),
            SKAction.fadeAlpha(to: 0.6, duration: 0.5)
        ])
        engineGlow.run(SKAction.repeatForever(pulseAction))
        
        ship.addChild(engineGlow)
        currentStageIndicator = ship
        currentStageIndicator?.position = CGPoint(x: centerX, y: startY)
        
        if let indicator = currentStageIndicator {
            scene?.addChild(indicator)
            roadmapNodes.append(indicator)
            
            let hover = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 1.0),
                SKAction.moveBy(x: 0, y: -3, duration: 1.0)
            ])
            indicator.run(SKAction.repeatForever(hover))
        }
    }
    
    func updateCurrentWave(_ wave: Int) {
        guard let scene = scene else { return }
        
        let spacing: CGFloat = 50 * layoutInfo.screenScaleFactor  // Scale the spacing
        let topMargin: CGFloat = isiPhoneSE ? 30 : 80
        let startY = scene.size.height - topMargin - (CGFloat(stageCount - 1) * spacing)
        let currentStage = wave == 0 ? 0 : (wave - 1) % stageCount
        let y = startY + CGFloat(currentStage) * spacing
        
        // Adjust the X position based on the device model
        let xPosition: CGFloat
        if isiPhoneSE {
            xPosition = 45 - 13.5  // Move left for iPhone SE
        } else {
            xPosition = 45  // Keep it as is for other devices
        }

        // Only move the existing indicator, don't create a new one
        if let indicator = currentStageIndicator {
            let moveAction = SKAction.move(to: CGPoint(x: xPosition, y: y), duration: 0.8)
            moveAction.timingMode = .easeInEaseOut
            indicator.run(moveAction)
        }
        
        // Update completed stages
        for i in 0..<stageDots.count {
            if i < currentStage {
                // Set the main shape to green
                stageDots[i].fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.8)
                stageDots[i].strokeColor = SKColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0)
                
                // If it's the asteroid stage, also update the craters
                if i == 2 {
                    stageDots[i].children.forEach { child in
                        if child.name == "crater" {
                            if let crater = child as? SKShapeNode {
                                crater.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.7)
                                crater.strokeColor = SKColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 0.8)
                            }
                        }
                    }
                }
            } else {
                // Reset stages after current stage to original colors
                if i == stageCount - 1 {  // Boss stage
                    updateBossStageColor(stageDots[i])
                } else if i == 2 {  // Asteroid stage
                    stageDots[i].fillColor = SKColor(red: 0.65, green: 0.63, blue: 0.62, alpha: 0.9)
                    stageDots[i].strokeColor = SKColor(red: 0.75, green: 0.73, blue: 0.72, alpha: 1.0)
                    // Reset crater colors
                    stageDots[i].children.forEach { child in
                        if child.name == "crater" {
                            if let crater = child as? SKShapeNode {
                                crater.fillColor = SKColor(red: 0.55, green: 0.53, blue: 0.52, alpha: 0.7)
                                crater.strokeColor = SKColor(red: 0.45, green: 0.43, blue: 0.42, alpha: 0.8)
                            }
                        }
                    }
                } else {  // Regular enemy stages
                    stageDots[i].fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.8)
                    stageDots[i].strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.6, alpha: 1.0)
                }
            }
        }
        
        // Move player indicator with adjusted X position
        if let indicator = currentStageIndicator {
            let moveAction = SKAction.move(to: CGPoint(x: xPosition, y: y), duration: 0.8)
            moveAction.timingMode = .easeInEaseOut
            indicator.run(moveAction)
        }
    }

    private func updateBossStageColor(_ marker: SKShapeNode) {
        // Fade out existing sprites before removing them
        let fadeOutAndRemove = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        
        // Remove existing sprites with fade out
        marker.children.forEach { child in
            child.run(fadeOutAndRemove)
        }
        
        
        // Wait briefly to ensure cleanup completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Create new boss sprite
            let spriteName = switch self.enemyManager.bossNum {
            case 2: "SadnessIcon"
            case 3: "DisgustIcon"
            case 4: "LoveIcon"
            default: "AngerIcon"
            }
            
            let bossSprite = SKSpriteNode(imageNamed: spriteName)
            bossSprite.alpha = 0 // Start invisible for fade in
            bossSprite.size = switch self.enemyManager.bossNum {
            case 2: CGSize(width: 50 * self.layoutInfo.screenScaleFactor, height: 30 * self.layoutInfo.screenScaleFactor)
            case 3: CGSize(width: 30 * self.layoutInfo.screenScaleFactor, height: 30 * self.layoutInfo.screenScaleFactor)
            case 4: CGSize(width: 30 * self.layoutInfo.screenScaleFactor, height: 30 * self.layoutInfo.screenScaleFactor)
            default: CGSize(width: 45 * self.layoutInfo.screenScaleFactor, height: 30 * self.layoutInfo.screenScaleFactor)
            }
            bossSprite.position = .zero
            marker.addChild(bossSprite)
            
            // Fade in the new sprite
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            bossSprite.run(fadeIn)
            
            // Add pulsing animation
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 1.0),
                SKAction.scale(to: 1.0, duration: 1.0)
            ])
            bossSprite.run(SKAction.repeatForever(pulse))
        }
    }
    
    func cleanup() {
        // Remove every node in the roadmap including the pointer
        for node in roadmapNodes {
            node.removeAllActions()
            node.removeFromParent()
        }
        currentStageIndicator?.removeAllActions()
        currentStageIndicator?.removeFromParent()
        currentStageIndicator = nil
        roadmapNodes.removeAll()
        stageDots.removeAll()
        
        // Also remove any nodes that might have the player indicator name
        scene?.enumerateChildNodes(withName: "playerIndicator") { node, _ in
            node.removeAllActions()
            node.removeFromParent()
        }
    }

    
    func hideRoadmap() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeOut) }
    }
    
    func showRoadmap() {
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeIn) }
    }
}
