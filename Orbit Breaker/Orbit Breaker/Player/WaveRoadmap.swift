//
//  WaveRoadmap.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/30/24.
//
import SpriteKit

class WaveRoadmap {
    private weak var scene: SKScene?
    private var roadmapNodes: [SKNode] = []
    private var stageDots: [SKShapeNode] = []
    private var currentStageIndicator: SKShapeNode?
    private let stageCount = 6  // 5 stages + boss
    
    init(scene: SKScene) {
        self.scene = scene
        setupRoadmap()
    }
    
    private func setupRoadmap() {
        guard let scene = scene else { return }
        
        cleanup()
        
        let spacing: CGFloat = 80
        let dotRadius: CGFloat = 15
        let topMargin: CGFloat = 80
        let centerX: CGFloat = 45
        let startY = scene.size.height - topMargin - (CGFloat(stageCount - 1) * spacing)
        
        // Create connecting "space path" with enhanced visibility
        let path = CGMutablePath()
        path.move(to: CGPoint(x: centerX, y: startY))
        path.addLine(to: CGPoint(x: centerX, y: startY + CGFloat(stageCount - 1) * spacing))
        
        // Add glowing background to path
        let glowPath = SKShapeNode(path: path)
        glowPath.strokeColor = SKColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.2)
        glowPath.lineWidth = 12
        glowPath.lineCap = .round
        glowPath.zPosition = 1
        
        let mainPath = SKShapeNode(path: path)
        mainPath.strokeColor = SKColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.4)
        mainPath.lineWidth = 4
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
            // Red angry face for boss
            marker.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.8)
            marker.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            
            // Add angry face details
            let face = SKShapeNode(circleOfRadius: radius * 0.8)
            face.fillColor = .clear
            face.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8)
            face.lineWidth = 2
            marker.addChild(face)
            
            // Add pulsing effect
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8)
            ])
            face.run(SKAction.repeatForever(pulse))
            
            // Add "spikes" around the boss marker
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                let spike = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: radius * 1.1 * cos(angle), y: radius * 1.1 * sin(angle)))
                path.addLine(to: CGPoint(x: radius * 1.4 * cos(angle), y: radius * 1.4 * sin(angle)))
                spike.path = path
                spike.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8)
                spike.lineWidth = 2
                marker.addChild(spike)
            }
            
        } else if stage == 2 {  // Asteroid field
            // Create a more rocky, irregular shape for the asteroid
            let asteroidPath = CGMutablePath()
            let points = 8
            var firstPoint = CGPoint.zero
            
            for i in 0..<points {
                let angle = CGFloat(i) * 2 * .pi / CGFloat(points)
                let randRadius = radius * CGFloat.random(in: 0.8...1.2)
                let x = cos(angle) * randRadius
                let y = sin(angle) * randRadius
                
                if i == 0 {
                    firstPoint = CGPoint(x: x, y: y)
                    asteroidPath.move(to: firstPoint)
                } else {
                    asteroidPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            asteroidPath.addLine(to: firstPoint)
            
            marker.path = asteroidPath
            marker.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8)
            marker.strokeColor = SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
            
            // Add "crater" details
            for _ in 0..<3 {
                let crater = SKShapeNode(circleOfRadius: radius * CGFloat.random(in: 0.2...0.3))
                crater.position = CGPoint(
                    x: radius * CGFloat.random(in: -0.4...0.4),
                    y: radius * CGFloat.random(in: -0.4...0.4)
                )
                crater.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.6)
                crater.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.8)
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
        // Create triangular ship shape
        let shipPath = CGMutablePath()
        shipPath.move(to: CGPoint(x: 0, y: 12))  // Top point
        shipPath.addLine(to: CGPoint(x: -8, y: -6))  // Bottom left
        shipPath.addLine(to: CGPoint(x: 8, y: -6))   // Bottom right
        shipPath.closeSubpath()
        
        let ship = SKShapeNode(path: shipPath)
        ship.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9)
        ship.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        ship.lineWidth = 2
        ship.zPosition = 10
        
        // Add engine glow
        let engineGlow = SKShapeNode(path: CGMutablePath())
        engineGlow.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.6)
        engineGlow.strokeColor = .clear
        engineGlow.position = CGPoint(x: 0, y: -8)
        
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
            
            // Add hover animation
            let hover = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 1.0),
                SKAction.moveBy(x: 0, y: -3, duration: 1.0)
            ])
            indicator.run(SKAction.repeatForever(hover))
        }
    }
    
    func updateCurrentWave(_ wave: Int) {
        guard let scene = scene else { return }
        
        let currentStage = (wave - 1) % stageCount
        let spacing: CGFloat = 80
        let topMargin: CGFloat = 80
        let startY = scene.size.height - topMargin - (CGFloat(stageCount - 1) * spacing)
        let y = startY + CGFloat(currentStage) * spacing
        
        // Update completed stages
        for i in 0..<stageDots.count {
            if i < currentStage {
                stageDots[i].fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.8)
                stageDots[i].strokeColor = SKColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0)
            }
        }
        
        // Move player indicator
        if let indicator = currentStageIndicator {
            let moveAction = SKAction.move(to: CGPoint(x: 45, y: y), duration: 0.8)
            moveAction.timingMode = .easeInEaseOut
            indicator.run(moveAction)
        }
    }
    
    func cleanup() {
        currentStageIndicator?.removeFromParent()
        currentStageIndicator = nil
        roadmapNodes.forEach {
            $0.removeAllActions()
            $0.removeFromParent()
        }
        roadmapNodes.removeAll()
        stageDots.removeAll()
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
