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
    private var currentWaveIndicator: SKShapeNode?
    private let waveCount = 5
    
    init(scene: SKScene) {
        self.scene = scene
        setupRoadmap()
    }
    
    func cleanup() {
        // Immediately remove the indicator from the scene if it exists
        currentWaveIndicator?.removeFromParent()
        currentWaveIndicator = nil
        
        roadmapNodes.forEach {
            $0.removeAllActions()
            $0.removeFromParent()
        }
        roadmapNodes.removeAll()
    }
    
    private func setupRoadmap() {
        guard let scene = scene else { return }
        
        cleanup()
        
        let spacing: CGFloat = 50
        let dotRadius: CGFloat = 8
        let topMargin: CGFloat = 50
        let centerX: CGFloat = 40
        
        let startY = scene.size.height - topMargin - (CGFloat(waveCount - 1) * spacing)
        
        // Create dots first
        for i in 0..<waveCount {
            let y = startY + CGFloat(i) * spacing
            
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = .white
            dot.strokeColor = .gray
            dot.position = CGPoint(x: centerX, y: y)
            dot.alpha = 0.7
            dot.zPosition = 1  // Higher zPosition for dots
            scene.addChild(dot)
            roadmapNodes.append(dot)
            
            if i == waveCount - 1 {
                let label = SKLabelNode(fontNamed: "Arial")
                label.text = "BOSS"
                label.fontSize = 14
                label.fontColor = .white
                label.position = CGPoint(x: centerX + 20, y: y - 6)
                label.horizontalAlignmentMode = .left
                scene.addChild(label)
                roadmapNodes.append(label)
            }
        }
        
        // Create lines after all dots
        for i in 1..<waveCount {
            let y = startY + CGFloat(i) * spacing
            let line = SKShapeNode(rectOf: CGSize(width: 2, height: spacing - 10))
            line.fillColor = .gray
            line.strokeColor = .clear
            line.zPosition = 0  // Set lowest zPosition for lines
            line.position = CGPoint(x: centerX, y: y - spacing/2)
            line.alpha = 0.5
            scene.addChild(line)
            roadmapNodes.append(line)
        }
    
        
        
        // Create the indicator only if it doesn't exist
        if currentWaveIndicator == nil {
            currentWaveIndicator = SKShapeNode(circleOfRadius: dotRadius + 4)
            if let indicator = currentWaveIndicator {
                indicator.strokeColor = .yellow
                indicator.lineWidth = 2
                indicator.position = CGPoint(x: centerX, y: startY)
                scene.addChild(indicator)
                
                let pulseAction = SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                indicator.run(SKAction.repeatForever(pulseAction))
            }
        }
    }
    
    func updateCurrentWave(_ wave: Int) {
        guard let scene = scene else { return }
        
        let adjustedWave = (wave - 1) % waveCount
        let spacing: CGFloat = 50
        let topMargin: CGFloat = 50
        let startY = scene.size.height - topMargin - (CGFloat(waveCount - 1) * spacing)
        let y = startY + CGFloat(adjustedWave) * spacing
        
        currentWaveIndicator?.removeAllActions()
        
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        
        let moveAction = SKAction.move(to: CGPoint(x: 40, y: y), duration: 0.5)
        moveAction.timingMode = .easeInEaseOut
        
        currentWaveIndicator?.run(SKAction.group([
            SKAction.repeatForever(pulseAction),
            moveAction
        ]))
    }
    
    func hideRoadmap() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeOut) }
        currentWaveIndicator?.run(fadeOut)
    }
    
    func showRoadmap() {
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeIn) }
        currentWaveIndicator?.run(fadeIn)
    }
}
